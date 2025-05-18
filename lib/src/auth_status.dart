/// Auth status enum representing the current authentication state.
enum AuthStatus {
  /// User is authenticated and session is valid
  authenticated,

  /// User is not authenticated or session is invalid
  unauthenticated,

  /// Authentication state is being determined
  loading,
}
