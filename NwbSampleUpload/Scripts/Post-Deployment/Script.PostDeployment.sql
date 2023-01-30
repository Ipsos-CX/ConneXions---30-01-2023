/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
/*
USE NwbSampleUpload


-- Create the nwbSampleUpload_user login if it doesn't already exist
IF NOT EXISTS (select * from master.dbo.syslogins where name = 'nwbSampleUpload_user')
BEGIN
	CREATE LOGIN nwbSampleUpload_user WITH PASSWORD = 'gCz2q2gJ3Qxx6htP'; 
END

-- Create the nwbSampleUpload_user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'nwbSampleUpload_user')
   CREATE USER [nwbSampleUpload_user] FOR LOGIN [nwbSampleUpload_user] WITH DEFAULT_SCHEMA=[dbo];
GO

exec sp_addrolemember 'db_owner', 'nwbSampleUpload_user';
*/