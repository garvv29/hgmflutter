Widget _buildPlantCard(int index) {
    final plant = _plants[index];
    final bool canUploadPhoto = plant.nextPhotoDate == null || 
        DateTime.now().isAfter(DateTime.parse(plant.nextPhotoDate!));
    
    String waitingText = '';
    Color statusColor;
    
    if (plant.photoCount >= 10) {
      waitingText = '';
      statusColor = AppTheme.successColor;
    } else if (plant.nextPhotoDate == null) {
      waitingText = '';
      statusColor = AppTheme.warningColor;
    } else {
      final nextDate = DateTime.parse(plant.nextPhotoDate!);
      final daysLeft = nextDate.difference(DateTime.now()).inDays;
      if (daysLeft <= 0) {
        waitingText = '';
        statusColor = AppTheme.warningColor;
      } else {
        waitingText = '${daysLeft.toString()} दिन बाकी';
        statusColor = AppTheme.errorColor;
      }
    }
    
    return Card(
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plant icon and waiting time
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_florist,
                      color: statusColor,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plant.name,
                      style: AppTheme.headingSmall,
                    ),
                    if (waitingText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          waitingText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.photo_camera,
                      onPressed: canUploadPhoto ? () => _takePhoto(index) : null,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.photo_library,
                      onPressed: plant.photos.isNotEmpty ? () => _showLatestPhoto(index) : null,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
