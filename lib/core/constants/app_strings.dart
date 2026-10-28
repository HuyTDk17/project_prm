/// User-facing messages (see the message list MSG01-MSG25 in the report).
abstract final class AppStrings {
  static const appName = 'MiniTube';

  static const emailRequired = 'Email is required.'; // MSG01
  static const emailInvalid = 'Invalid email format.'; // MSG02
  static const passwordInvalid = 'Password must be 6-32 characters.'; // MSG03
  static const invalidCredentials = 'Invalid email or password.'; // MSG06
  static const displayNameInvalid = 'Display name must be 2-50 characters.'; // MSG25
  static const passwordMismatch = 'Passwords do not match.'; // MSG04
  static const emailTaken = 'This email is already registered.'; // MSG05
  static const channelNameInvalid = 'Channel name must be 3-50 characters.'; // MSG07
  static const channelNameTaken = 'This channel name already exists.'; // MSG08
  static const maxChannels = 'You can own at most 5 channels.'; // MSG27
  static const videoRequired = 'Please select a video file.'; // MSG10
  static const videoTooLarge = 'The video must be 100 MB or smaller.'; // BR06
  static const titleInvalid = 'Title is required (1-100 characters).'; // MSG09
  static const categoryRequired = 'Please choose a category.';
  static const uploadSuccess = 'Video uploaded successfully.'; // MSG11
  static const cloudinaryMissing =
      'Cloudinary is not configured. Set the cloud name and upload preset in lib/core/config/cloudinary_config.dart.';
  static const googleCancelled = 'Google sign-in was cancelled.';
  static const googlePopupBlocked = 'The browser blocked the Google window. Allow pop-ups for this site and try again.';
  static const googleDisabled = 'Google sign-in is not enabled in the Firebase project.';
  static const accountExistsOtherMethod =
      'This email is already registered with a password. Log in with your email and password.';
  static const commentEmpty = 'Comment cannot be empty.'; // MSG15
  static const commentTooLong = 'Comment must be at most 500 characters.'; // MSG16
  static const noNotifications = 'You have no notifications yet.'; // MSG19
  static const historyEmpty = 'Your watch history is empty.'; // MSG20
  static const videoUpdated = 'Video updated successfully.'; // MSG12
  static const videoDeleted = 'Video deleted.'; // MSG14
  static const deleteVideoConfirm = 'Delete this video? This action cannot be undone.'; // MSG13
  static const channelSaved = 'Channel saved.';
  static const descriptionTooLong = 'Description must be at most 1000 characters.';
  static const noVideos = 'No videos found.'; // MSG18
  static const genericError = 'Something went wrong. Please try again.'; // MSG23
}
