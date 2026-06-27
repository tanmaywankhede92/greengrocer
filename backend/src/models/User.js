const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { APP_ROLES } = require('../constants/enums');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    trim: true,
    lowercase: true,
    maxlength: 255,
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: 6,
    maxlength: 72,
    select: false,
  },
  fullName: {
    type: String,
    required: [true, 'Full name is required'],
    trim: true,
    maxlength: 100,
  },
  role: {
    type: String,
    enum: APP_ROLES,
    default: 'staff',
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  refreshToken: {
    type: String,
    select: false,
  },
  resetPasswordToken: String,
  resetPasswordExpires: Date,
  lastLoginAt: Date,
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
}, { timestamps: true });


userSchema.index({ role: 1 });

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  delete obj.refreshToken;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
