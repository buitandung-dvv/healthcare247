CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('Male', 'Female', 'Other')),
    date_of_birth DATE,
    height DECIMAL(5,2),
    weight DECIMAL(5,2),
    goal VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Exercises (
    exercise_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) CHECK (type IN ('cardio','strength','flexibility','balance')),
    level VARCHAR(50) CHECK (level IN ('beginner','intermediate','advanced')),
    calories_burned_per_hour DECIMAL(10,2)
);

CREATE TABLE Foods (
    food_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    calories DECIMAL(10,2),
    protein DECIMAL(10,2),
    fat DECIMAL(10,2),
    carbs DECIMAL(10,2)
);

CREATE TABLE Meals (
    meal_id INT PRIMARY KEY AUTO_INCREMENT,
    meal_type VARCHAR(50) CHECK (meal_type IN ('breakfast','lunch','dinner','snack')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Meal_Food_Items (
    meal_id INT,
    food_id INT,
    quantity DECIMAL(10,2),
    PRIMARY KEY (meal_id, food_id),
    FOREIGN KEY (meal_id) REFERENCES Meals(meal_id),
    FOREIGN KEY (food_id) REFERENCES Foods(food_id)
);

CREATE TABLE Plans (
    plan_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    plan_type VARCHAR(50) CHECK (plan_type IN ('nutrition','workout','mixed')),
    description VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Plan_Details (
    detail_id INT AUTO_INCREMENT PRIMARY KEY,
    plan_id INT NOT NULL,
    day_of_week INT NOT NULL,
    exercise_id INT NULL,
    meal_id INT NULL,
    FOREIGN KEY (plan_id) REFERENCES Plans(plan_id),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id),
    FOREIGN KEY (meal_id) REFERENCES Meals(meal_id)
);

CREATE TABLE Plan_Exercises (
    plan_id INT,
    exercise_id INT,
    duration_minutes INT,
    PRIMARY KEY (plan_id, exercise_id),
    FOREIGN KEY (plan_id) REFERENCES Plans(plan_id),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id)
);

CREATE TABLE Plan_Meals (
    plan_id INT,
    meal_id INT,
    PRIMARY KEY (plan_id, meal_id),
    FOREIGN KEY (plan_id) REFERENCES Plans(plan_id),
    FOREIGN KEY (meal_id) REFERENCES Meals(meal_id)
);

CREATE TABLE Exercise_Tracking (
    tracking_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    exercise_id INT,
    duration_minutes INT,
    calories_burned DECIMAL(10,2),
    date DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id)
);

CREATE TABLE Meal_Tracking (
    tracking_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    meal_id INT,
    date DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (meal_id) REFERENCES Meals(meal_id)
);

CREATE TABLE AI_Recommendations (
    rec_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    date DATE,
    recommendation TEXT,
    source VARCHAR(10) CHECK (source IN ('system','AI')),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Achievements (
    achievement_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    icon_url VARCHAR(255)
);

CREATE TABLE User_Achievements (
    user_id INT NOT NULL,
    achievement_id INT NOT NULL,
    earned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, achievement_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (achievement_id) REFERENCES Achievements(achievement_id)
);

CREATE TABLE Friendships (
    user_id INT,
    friend_id INT,
    status VARCHAR(20) CHECK (status IN ('pending','accepted','blocked')),
    PRIMARY KEY (user_id, friend_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (friend_id) REFERENCES Users(user_id),
    CHECK (user_id <> friend_id)
);

CREATE TABLE Challenges (
    challenge_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    duration_days INT,
    reward VARCHAR(255)
);

CREATE TABLE User_Challenges (
    user_id INT NOT NULL,
    challenge_id INT NOT NULL,
    progress INT DEFAULT 0,
    status VARCHAR(20) CHECK (status IN ('in_progress','completed','failed')) DEFAULT 'in_progress',
    start_date DATE,
    end_date DATE,
    PRIMARY KEY (user_id, challenge_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (challenge_id) REFERENCES Challenges(challenge_id)
);

CREATE TABLE Notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    message TEXT,
    type VARCHAR(20) CHECK (type IN ('reminder','achievement','system')) DEFAULT 'system',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
