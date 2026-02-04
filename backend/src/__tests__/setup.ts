// Jest setup file
// This runs before each test file

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-key';
process.env.PORT = '5001';

// Extend Jest matchers if needed
expect.extend({
    toBeWithinRange(received: number, floor: number, ceiling: number) {
        const pass = received >= floor && received <= ceiling;
        if (pass) {
            return {
                message: () => `expected ${received} not to be within range ${floor} - ${ceiling}`,
                pass: true,
            };
        } else {
            return {
                message: () => `expected ${received} to be within range ${floor} - ${ceiling}`,
                pass: false,
            };
        }
    },
});

// Global test timeout
jest.setTimeout(10000);

// Silence console during tests (optional)
// beforeAll(() => {
//   jest.spyOn(console, 'log').mockImplementation(() => {});
//   jest.spyOn(console, 'error').mockImplementation(() => {});
// });
