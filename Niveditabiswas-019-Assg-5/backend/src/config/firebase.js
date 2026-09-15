const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

let db;
let auth;
let isInitialized = false;

try {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || path.join(__dirname, '../../serviceAccountKey.json');

  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    db = admin.firestore();
    auth = admin.auth();
    isInitialized = true;
    console.log('✅ Firebase Admin SDK initialized successfully via serviceAccountKey.json');
  } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
    });
    db = admin.firestore();
    auth = admin.auth();
    isInitialized = true;
    console.log('✅ Firebase Admin SDK initialized successfully via Environment Variables');
  } else {
    console.warn('⚠️ No Firebase credentials found. Initializing in Fallback Database Mode for development/testing.');
  }
} catch (err) {
  console.warn('⚠️ Error initializing Firebase Admin SDK:', err.message);
}

// In-Memory Database Fallback for development/testing when live Firebase credentials are not yet provided
class MemoryCollection {
  constructor(name) {
    this.name = name;
    this.docs = new Map();
  }

  doc(id) {
    const docId = id || Math.random().toString(36).substring(2, 15);
    const self = this;
    return {
      id: docId,
      set: async (data, options = {}) => {
        const existing = self.docs.get(docId) || {};
        const updated = options.merge ? { ...existing, ...data } : data;
        self.docs.set(docId, { id: docId, ...updated });
        return { writeTime: new Date() };
      },
      update: async (data) => {
        const existing = self.docs.get(docId);
        if (!existing) throw new Error(`Document ${docId} not found`);
        const updated = { ...existing, ...data };
        self.docs.set(docId, updated);
        return { writeTime: new Date() };
      },
      get: async () => {
        const data = self.docs.get(docId);
        return {
          exists: !!data,
          id: docId,
          data: () => (data ? { ...data } : undefined),
        };
      },
      delete: async () => {
        self.docs.delete(docId);
        return { writeTime: new Date() };
      },
    };
  }

  async add(data) {
    const id = Math.random().toString(36).substring(2, 15);
    const docRef = this.doc(id);
    await docRef.set(data);
    return docRef;
  }

  async get() {
    const list = Array.from(this.docs.values()).map((data) => ({
      id: data.id,
      data: () => ({ ...data }),
    }));
    return {
      docs: list,
      empty: list.length === 0,
      size: list.length,
      forEach: (cb) => list.forEach(cb),
    };
  }

  where(field, op, value) {
    const self = this;
    return {
      get: async () => {
        let items = Array.from(self.docs.values());
        if (op === '==' || op === '===') {
          items = items.filter((d) => d[field] === value);
        } else if (op === '>=') {
          items = items.filter((d) => d[field] >= value);
        } else if (op === '<=') {
          items = items.filter((d) => d[field] <= value);
        } else if (op === 'in') {
          items = items.filter((d) => Array.isArray(value) && value.includes(d[field]));
        }
        const docs = items.map((data) => ({
          id: data.id,
          data: () => ({ ...data }),
        }));
        return {
          docs,
          empty: docs.length === 0,
          size: docs.length,
          forEach: (cb) => docs.forEach(cb),
        };
      },
      orderBy: () => ({
        get: async () => {
          const docs = Array.from(self.docs.values()).map((data) => ({
            id: data.id,
            data: () => ({ ...data }),
          }));
          return { docs, empty: docs.length === 0, size: docs.length, forEach: (cb) => docs.forEach(cb) };
        },
      }),
    };
  }

  orderBy(field, direction = 'asc') {
    const self = this;
    return {
      get: async () => {
        let items = Array.from(self.docs.values());
        items.sort((a, b) => {
          if (direction === 'desc') return (b[field] || 0) > (a[field] || 0) ? 1 : -1;
          return (a[field] || 0) > (b[field] || 0) ? 1 : -1;
        });
        const docs = items.map((data) => ({
          id: data.id,
          data: () => ({ ...data }),
        }));
        return { docs, empty: docs.length === 0, size: docs.length, forEach: (cb) => docs.forEach(cb) };
      },
    };
  }
}

class FallbackDatabase {
  constructor() {
    this.collections = new Map();
  }

  collection(name) {
    if (!this.collections.has(name)) {
      this.collections.set(name, new MemoryCollection(name));
    }
    return this.collections.get(name);
  }
}

if (!db) {
  db = new FallbackDatabase();
}

module.exports = {
  admin,
  db,
  auth,
  isInitialized,
};
