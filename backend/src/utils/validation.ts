/**
 * Utility functions for input validation
 */

/**
 * Parse integer from string with NaN validation
 * @param value - String value to parse
 * @param defaultValue - Default value if parsing fails (optional)
 * @returns Parsed integer or null/default if invalid
 */
export const parseIntSafe = (value: string | undefined, defaultValue?: number): number | null => {
    if (!value) return defaultValue ?? null;
    const parsed = parseInt(value, 10);
    return isNaN(parsed) ? (defaultValue ?? null) : parsed;
};

/**
 * Parse integer with strict validation (throws on invalid)
 * @param value - String value to parse
 * @param fieldName - Name of field for error message
 * @returns Parsed integer
 * @throws Error if value is invalid
 */
export const parseIntStrict = (value: string | undefined, fieldName: string): number => {
    if (!value) {
        throw new Error(`${fieldName} is required`);
    }
    const parsed = parseInt(value, 10);
    if (isNaN(parsed)) {
        throw new Error(`${fieldName} must be a valid number`);
    }
    return parsed;
};

/**
 * Parse positive integer (for IDs)
 * @param value - String value to parse
 * @param fieldName - Name of field for error message
 * @returns Parsed positive integer or null if invalid
 */
export const parseIdParam = (value: string | undefined, fieldName: string = 'ID'): number | null => {
    if (!value) return null;
    const parsed = parseInt(value, 10);
    if (isNaN(parsed) || parsed <= 0) {
        return null;
    }
    return parsed;
};

/**
 * Validation result type
 */
export interface ValidationError {
    field: string;
    message: string;
}

/**
 * Validate request params and return errors
 */
export const validateParams = (
    params: Record<string, string | undefined>,
    required: string[]
): ValidationError[] => {
    const errors: ValidationError[] = [];

    for (const field of required) {
        const value = params[field];
        if (!value) {
            errors.push({ field, message: `${field} is required` });
            continue;
        }

        // If field ends with 'id' or 'Id', validate as positive integer
        if (field.toLowerCase().endsWith('id')) {
            const parsed = parseInt(value, 10);
            if (isNaN(parsed) || parsed <= 0) {
                errors.push({ field, message: `${field} must be a valid positive number` });
            }
        }
    }

    return errors;
};
