CREATE PROCEDURE [Migration].[uspAddMetadata]
AS

INSERT INTO dbo.FTPScriptMetadata (FTPProcessName, HostName, UserID, Password, RemoteDirectory, LocalDownloadDirectory, DataFileExtension, LocalArchiveDirectoryPath, TransferMode, UpDown, Enabled) VALUES
('Sample File Download', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/SampleToLoad/', 'P:\Sampling\DataLoading\SampleFiles\Download', '*', NULL, 'binary', 'D', 1),
('Selection Output Upload', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/SelectionOutput/', 'P:\Sampling\DataOutput\SelectionOutput', '.xlsx', NULL, 'binary', 'U', 1),
('Customer Update - Contact Outcome', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/CustomerUpdates/ContactOutcome/', 'P:\Sampling\DataLoading\CustomerUpdateFiles\ContactOutcome', '*.txt', NULL, 'binary', 'D', 1),
('Customer Update - Dealer', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/CustomerUpdates/Dealer/', 'P:\Sampling\DataLoading\CustomerUpdateFiles\Dealer', '*.txt', NULL, 'binary', 'D', 1),
('Customer Update - Email Address', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/CustomerUpdates/ElectronicAddress/', 'P:\Sampling\DataLoading\CustomerUpdateFiles\EmailAddress', '*.txt', NULL, 'binary', 'D', 1),
('Customer Update - Organisation', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/CustomerUpdates/Organisation/', 'P:\Sampling\DataLoading\CustomerUpdateFiles\Organisation', '*.txt', NULL, 'binary', 'D', 1),
('Customer Update - Person', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/CustomerUpdates/Person/', 'P:\Sampling\DataLoading\CustomerUpdateFiles\Person', '*.txt', NULL, 'binary', 'D', 1),
('Customer Update - Postal Address', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/CustomerUpdates/PostalAddress/', 'P:\Sampling\DataLoading\CustomerUpdateFiles\PostalAddress', '*.txt', NULL, 'binary', 'D', 1),
('Customer Update - Registration Number', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/CustomerUpdates/RegistrationNumber/', 'P:\Sampling\DataLoading\CustomerUpdateFiles\RegistrationNumber', '*.txt', NULL, 'binary', 'D', 1),
('Customer Update - Telephone Number', 'ftps.gfk.com', 'jlrcsp', 'I92!nvt$QW', '/CustomerUpdates/TelephoneNumber/', 'P:\Sampling\DataLoading\CustomerUpdateFiles\TelephoneNumber', '*.txt', NULL, 'binary', 'D', 1)

