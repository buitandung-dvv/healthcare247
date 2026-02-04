import { connectDB, closeDB } from '../config/database';
import { workoutSessionService } from '../services/workout-session.service';

const debugSession = async () => {
    try {
        console.log('Connecting to database...');
        await connectDB();

        console.log('Attempting to start session...');
        // Mock user ID 1 (assuming it exists, or we'll see FK error if constraint exists)
        // Pass undefined for plan/exercise to test Freestyle logic
        try {
            const session = await workoutSessionService.startSession(1, undefined, undefined, 'Debug Session');
            console.log('✅ Session started successfully:', session);
        } catch (e: any) {
            console.error('❌ Error in startSession:', e);
            console.error('❌ Error details:', JSON.stringify(e, null, 2));
        }

    } catch (error) {
        console.error('❌ Script setup error:', error);
    } finally {
        await closeDB();
        process.exit(0);
    }
};

debugSession();
