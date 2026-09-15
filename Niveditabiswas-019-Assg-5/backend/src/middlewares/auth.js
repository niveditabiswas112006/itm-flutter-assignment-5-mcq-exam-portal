const { auth, db, isInitialized } = require('../config/firebase');

/**
 * Authentication Middleware
 * Validates Firebase ID Token or mock authentication header for development
 */
const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    // Support Dev Mode / Demo header if token isn't provided or during local testing
    if (req.headers['x-mock-user-id']) {
      req.user = {
        uid: req.headers['x-mock-user-id'],
        email: req.headers['x-mock-user-email'] || 'admin@itm.edu',
        role: req.headers['x-mock-user-role'] || 'admin',
        name: req.headers['x-mock-user-name'] || 'Demo User',
      };
      return next();
    }

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // In development fallback, default to an admin mock if Firebase not configured
      if (!isInitialized) {
        req.user = {
          uid: 'dev-admin-uid-1',
          email: 'admin@itm.edu',
          role: 'admin',
          name: 'ITM Admin',
        };
        return next();
      }
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: No token provided in Authorization header.',
      });
    }

    const token = authHeader.split('Bearer ')[1];

    if (isInitialized && auth) {
      const decodedToken = await auth.verifyIdToken(token);
      
      // Fetch user role from Firestore 'users' collection
      let role = decodedToken.role || 'student';
      let name = decodedToken.name || decodedToken.email;
      let photoUrl = decodedToken.picture || '';

      const userDoc = await db.collection('users').doc(decodedToken.uid).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        role = userData.role || role;
        name = userData.name || name;
        photoUrl = userData.photoUrl || photoUrl;
      }

      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        role: role,
        name: name,
        photoUrl: photoUrl,
      };
    } else {
      // Fallback decode for development
      req.user = {
        uid: 'dev-user-uid',
        email: 'user@itm.edu',
        role: 'admin',
        name: 'Dev User',
      };
    }

    next();
  } catch (err) {
    console.error('[Auth Middleware Error]:', err.message);
    return res.status(401).json({
      success: false,
      message: 'Unauthorized: Invalid or expired authentication token.',
      error: err.message,
    });
  }
};

/**
 * Enforce Admin Role
 */
const requireAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Forbidden: Admin privileges are required to access this endpoint.',
    });
  }
  next();
};

/**
 * Enforce Student Role (or Admin access)
 */
const requireStudent = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized: Please log in.',
    });
  }
  next();
};

module.exports = {
  requireAuth,
  requireAdmin,
  requireStudent,
};
