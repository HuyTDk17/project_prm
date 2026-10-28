enum UserRole {
  viewer('Viewer'),
  channelManager('Channel manager');

  const UserRole(this.label);
  final String label;

  bool get canManageChannel => this == UserRole.channelManager;
}
