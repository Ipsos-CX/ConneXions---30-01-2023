CREATE PROCEDURE [Migration].[uspAddMetadata]
AS

SET IDENTITY_INSERT dbo.FileFailureReasons ON
INSERT INTO dbo.FileFailureReasons (FileFailureID, FileFailureReason) VALUES
(1, 	'General loading error'),
(2, 	'File already exists'),
(3, 	'Failed to load from Staging table to VWT')
SET IDENTITY_INSERT dbo.FileFailureReasons OFF