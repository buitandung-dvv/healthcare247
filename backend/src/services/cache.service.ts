/**
 * In-Memory Cache Service
 * Simple caching layer for static/semi-static data like categories, levels, equipment
 */

interface CacheEntry<T> {
    data: T;
    expiry: number;
}

export class CacheService {
    private cache = new Map<string, CacheEntry<unknown>>();
    private readonly defaultTTL: number;

    constructor(defaultTTLMinutes: number = 30) {
        this.defaultTTL = defaultTTLMinutes * 60 * 1000;
    }

    /**
     * Get cached data or fetch and cache it
     */
    async getOrSet<T>(
        key: string,
        fetchFn: () => Promise<T>,
        ttlMinutes?: number
    ): Promise<T> {
        // Check if cache exists and is valid
        const existing = this.cache.get(key) as CacheEntry<T> | undefined;
        if (existing && Date.now() < existing.expiry) {
            console.log(`📦 Cache hit: ${key}`);
            return existing.data;
        }

        // Fetch fresh data
        console.log(`🌐 Cache miss, fetching: ${key}`);
        const data = await fetchFn();

        // Store in cache
        const ttl = ttlMinutes ? ttlMinutes * 60 * 1000 : this.defaultTTL;
        this.cache.set(key, {
            data,
            expiry: Date.now() + ttl,
        });

        return data;
    }

    /**
     * Set data directly in cache
     */
    set<T>(key: string, data: T, ttlMinutes?: number): void {
        const ttl = ttlMinutes ? ttlMinutes * 60 * 1000 : this.defaultTTL;
        this.cache.set(key, {
            data,
            expiry: Date.now() + ttl,
        });
    }

    /**
     * Get data from cache (returns undefined if expired or not found)
     */
    get<T>(key: string): T | undefined {
        const entry = this.cache.get(key) as CacheEntry<T> | undefined;
        if (entry && Date.now() < entry.expiry) {
            return entry.data;
        }
        // Remove expired entry
        if (entry) {
            this.cache.delete(key);
        }
        return undefined;
    }

    /**
     * Remove specific key from cache
     */
    delete(key: string): boolean {
        return this.cache.delete(key);
    }

    /**
     * Invalidate all entries matching a pattern
     */
    invalidatePattern(pattern: string): number {
        let count = 0;
        for (const key of this.cache.keys()) {
            if (key.includes(pattern)) {
                this.cache.delete(key);
                count++;
            }
        }
        console.log(`🗑️ Invalidated ${count} cache entries matching: ${pattern}`);
        return count;
    }

    /**
     * Clear all cache
     */
    clear(): void {
        this.cache.clear();
        console.log('🗑️ Cache cleared');
    }

    /**
     * Clean up expired entries
     */
    cleanup(): number {
        const now = Date.now();
        let count = 0;
        for (const [key, entry] of this.cache.entries()) {
            if (now >= entry.expiry) {
                this.cache.delete(key);
                count++;
            }
        }
        return count;
    }

    /**
     * Get cache statistics
     */
    stats(): { size: number; keys: string[] } {
        return {
            size: this.cache.size,
            keys: Array.from(this.cache.keys()),
        };
    }
}

// Cache keys for different data types
export const CacheKeys = {
    // Static data (long TTL - 1 hour)
    CATEGORIES: 'static:categories',
    LEVELS: 'static:levels',
    EQUIPMENTS: 'static:equipments',
    MUSCLES: (langId: number) => `static:muscles:${langId}`,
    RECIPE_CATEGORIES: 'static:recipe_categories',
    RECIPE_AREAS: 'static:recipe_areas',

    // User-specific data (short TTL - 5 minutes)
    USER_GOALS: (userId: number) => `user:goals:${userId}`,
    USER_FAVORITES: (userId: number) => `user:favorites:${userId}`,

    // Exercise/Recipe details (medium TTL - 15 minutes)
    EXERCISE_DETAIL: (id: number, langId: number) => `exercise:${id}:${langId}`,
    RECIPE_DETAIL: (id: number, langId: number) => `recipe:${id}:${langId}`,
};

// Singleton instance with 30 minute default TTL
export const cacheService = new CacheService(30);
