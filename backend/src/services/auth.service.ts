import { getPool, sql } from '../config/database';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { User, UserCreateDTO, UserUpdateDTO, AuthResponse } from '../types';

export class AuthService {
  // Register new user
  async register(data: UserCreateDTO): Promise<AuthResponse> {
    const pool = getPool();

    // Check if user exists
    const existingUser = await pool.request()
      .input('email', sql.NVarChar, data.email)
      .input('username', sql.NVarChar, data.username)
      .query(`
        SELECT user_id FROM Users
        WHERE email = @email OR username = @username
      `);

    if (existingUser.recordset.length > 0) {
      throw new Error('User with this email or username already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(data.password, 12);

    // Insert user - use separate INSERT and SELECT to avoid OUTPUT clause trigger issue
    await pool.request()
      .input('username', sql.NVarChar, data.username)
      .input('password', sql.NVarChar, hashedPassword)
      .input('email', sql.NVarChar, data.email)
      .input('gender', sql.NVarChar, data.gender || null)
      .input('date_of_birth', sql.Date, data.date_of_birth ? new Date(data.date_of_birth) : null)
      .input('height', sql.Decimal(5, 2), data.height || null)
      .input('weight', sql.Decimal(5, 2), data.weight || null)
      .input('goal', sql.NVarChar, data.goal || null)
      .input('preferred_language_id', sql.Int, data.preferred_language_id || 1)
      .query(`
        INSERT INTO Users (username, password, email, gender, date_of_birth, height, weight, goal, preferred_language_id, onboarding_completed)
        VALUES (@username, @password, @email, @gender, @date_of_birth, @height, @weight, @goal, @preferred_language_id, 0)
      `);

    // Get the newly created user using SCOPE_IDENTITY()
    const result = await pool.request()
      .input('email', sql.NVarChar, data.email)
      .query(`
        SELECT user_id, username, email, full_name, gender, date_of_birth, height, weight, goal, 
               body_goals, activity_level, preferred_language_id, onboarding_completed, created_at
        FROM Users WHERE email = @email
      `);

    const user = result.recordset[0];
    const token = this.generateToken(user.user_id);

    return { user, token };
  }

  // Login
  async login(email: string, password: string): Promise<AuthResponse> {
    const pool = getPool();

    const result = await pool.request()
      .input('email', sql.NVarChar, email)
      .query(`SELECT * FROM Users WHERE email = @email`);

    if (result.recordset.length === 0) {
      throw new Error('Invalid email or password');
    }

    const user = result.recordset[0];
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      throw new Error('Invalid email or password');
    }

    delete user.password;
    const token = this.generateToken(user.user_id);

    return { user, token };
  }

  // Get user by ID
  async getUserById(userId: number): Promise<User | null> {
    const pool = getPool();

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .query(`
        SELECT user_id, username, email, full_name, gender, date_of_birth, height, weight, goal, 
               body_goals, activity_level, preferred_language_id, onboarding_completed, created_at
        FROM Users WHERE user_id = @user_id
      `);

    return result.recordset[0] || null;
  }

  // Update user
  async updateUser(userId: number, data: UserUpdateDTO): Promise<User | null> {
    const pool = getPool();

    const updates: string[] = [];
    const request = pool.request().input('user_id', sql.Int, userId);

    if (data.username) {
      updates.push('username = @username');
      request.input('username', sql.NVarChar, data.username);
    }
    if (data.email) {
      updates.push('email = @email');
      request.input('email', sql.NVarChar, data.email);
    }
    if (data.full_name !== undefined) {
      updates.push('full_name = @full_name');
      request.input('full_name', sql.NVarChar, data.full_name);
    }
    if (data.gender !== undefined) {
      updates.push('gender = @gender');
      request.input('gender', sql.NVarChar, data.gender);
    }
    if (data.date_of_birth !== undefined) {
      updates.push('date_of_birth = @date_of_birth');
      request.input('date_of_birth', sql.Date, data.date_of_birth ? new Date(data.date_of_birth) : null);
    }
    if (data.height !== undefined) {
      updates.push('height = @height');
      request.input('height', sql.Decimal(5, 2), data.height);
    }
    if (data.weight !== undefined) {
      updates.push('weight = @weight');
      request.input('weight', sql.Decimal(5, 2), data.weight);
    }
    if (data.goal !== undefined) {
      updates.push('goal = @goal');
      request.input('goal', sql.NVarChar, data.goal);
    }
    if (data.body_goals !== undefined) {
      updates.push('body_goals = @body_goals');
      request.input('body_goals', sql.NVarChar, data.body_goals);
    }
    if (data.activity_level !== undefined) {
      updates.push('activity_level = @activity_level');
      request.input('activity_level', sql.NVarChar, data.activity_level);
    }
    if (data.preferred_language_id !== undefined) {
      updates.push('preferred_language_id = @preferred_language_id');
      request.input('preferred_language_id', sql.Int, data.preferred_language_id);
    }
    if (data.onboarding_completed !== undefined) {
      updates.push('onboarding_completed = @onboarding_completed');
      request.input('onboarding_completed', sql.Bit, data.onboarding_completed ? 1 : 0);
    }

    if (updates.length === 0) {
      return this.getUserById(userId);
    }

    const result = await request.query(`
      UPDATE Users SET ${updates.join(', ')}
      OUTPUT INSERTED.user_id, INSERTED.username, INSERTED.email, INSERTED.full_name, INSERTED.gender,
             INSERTED.date_of_birth, INSERTED.height, INSERTED.weight, INSERTED.goal,
             INSERTED.body_goals, INSERTED.activity_level, INSERTED.preferred_language_id, 
             INSERTED.onboarding_completed, INSERTED.created_at
      WHERE user_id = @user_id
    `);

    // Sync: Add weight tracking entry when weight is updated
    if (data.weight !== undefined && data.weight !== null) {
      await pool.request()
        .input('user_id', sql.Int, userId)
        .input('weight', sql.Decimal(5, 2), data.weight)
        .input('tracked_at', sql.DateTime, new Date())
        .query(`
          INSERT INTO Weight_Tracking (user_id, weight, notes, tracked_at)
          VALUES (@user_id, @weight, NULL, @tracked_at)
        `);
    }

    return result.recordset[0] || null;
  }

  // Social login (Google/Facebook)
  async socialLogin(data: {
    provider: string;
    provider_id: string;
    email: string;
    name: string;
    photo_url?: string;
  }): Promise<AuthResponse> {
    const pool = getPool();

    // Check if user exists by email
    const existingUser = await pool.request()
      .input('email', sql.NVarChar, data.email)
      .query(`
        SELECT user_id, username, email, full_name, gender, date_of_birth, height, weight, goal, 
               body_goals, activity_level, preferred_language_id, onboarding_completed, created_at
        FROM Users WHERE email = @email
      `);

    if (existingUser.recordset.length > 0) {
      // User exists
      let user = existingUser.recordset[0];

      // Update full_name if missing and we have a name from social provider
      if (!user.full_name && data.name) {
        await pool.request()
          .input('user_id', sql.Int, user.user_id)
          .input('full_name', sql.NVarChar, data.name)
          .query(`UPDATE Users SET full_name = @full_name WHERE user_id = @user_id`);
        user.full_name = data.name;
        console.log(`✅ Social login: updated full_name for ${user.email}`);
      }

      const token = this.generateToken(user.user_id);
      console.log(`✅ Social login: existing user ${user.email}`);
      return { user, token };
    }

    // Use email as username (unique), save display name as full_name
    const username = data.email;
    const fullName = data.name || null;

    // Create new user for social login (no password)
    await pool.request()
      .input('username', sql.NVarChar, username)
      .input('email', sql.NVarChar, data.email)
      .input('full_name', sql.NVarChar, fullName)
      .input('provider', sql.NVarChar, data.provider)
      .input('provider_id', sql.NVarChar, data.provider_id)
      .query(`
        INSERT INTO Users (username, email, full_name, password, preferred_language_id, onboarding_completed)
        VALUES (@username, @email, @full_name, 'SOCIAL_LOGIN', 1, 0)
      `);

    // Get the newly created user
    const result = await pool.request()
      .input('email', sql.NVarChar, data.email)
      .query(`
        SELECT user_id, username, email, full_name, gender, date_of_birth, height, weight, goal, 
               body_goals, activity_level, preferred_language_id, onboarding_completed, created_at
        FROM Users WHERE email = @email
      `);

    const user = result.recordset[0];
    const token = this.generateToken(user.user_id);
    console.log(`✅ Social login: new user created ${user.email}`);

    return { user, token };
  }

  // Generate JWT token
  private generateToken(userId: number): string {
    return jwt.sign({ userId }, config.jwt.secret, {
      expiresIn: config.jwt.expiresIn as string,
    } as jwt.SignOptions);
  }
}

export const authService = new AuthService();

