/**
 * Application constants
 * Centralizes magic numbers and default values
 */

export const PAGINATION = {
    DEFAULT_PAGE: 1,
    DEFAULT_LIMIT: 20,
    MAX_LIMIT: 100,
} as const;

export const DEFAULTS = {
    /** Default daily water intake goal in milliliters */
    WATER_GOAL_ML: 2000,
    /** Default limit for exercise tracking queries */
    EXERCISE_TRACKING_LIMIT: 100,
    /** Default limit for weight history queries */
    WEIGHT_HISTORY_LIMIT: 30,
    /** Default limit for water history queries */
    WATER_HISTORY_LIMIT: 50,
    /** Default meal quantity in grams */
    MEAL_QUANTITY: 100,
} as const;

export const BCRYPT = {
    /** Number of salt rounds for password hashing */
    SALT_ROUNDS: 12,
} as const;

export const VALIDATION = {
    /** Minimum password length */
    MIN_PASSWORD_LENGTH: 6,
    /** Maximum notes length */
    MAX_NOTES_LENGTH: 500,
    /** Maximum name length */
    MAX_NAME_LENGTH: 255,
} as const;
