CREATE FUNCTION [Party].[udfGetFullName]
(@Title [dbo].[Title], @FirstName [dbo].[NameDetail], @Initials [dbo].[NameDetail], @MiddleName [dbo].[NameDetail], @LastName [dbo].[NameDetail], @SecondLastName [dbo].[NameDetail])
RETURNS NVARCHAR (700)
AS
BEGIN
	
	DECLARE @FullName NVARCHAR(700)
	
	SET @Title = LTRIM(RTRIM(ISNULL(@Title, N'')))
	SET @FirstName = LTRIM(RTRIM(ISNULL(@FirstName, N'')))
	SET @Initials = LTRIM(RTRIM(ISNULL(@Initials, N'')))
	SET @MiddleName = LTRIM(RTRIM(ISNULL(@MiddleName, N'')))
	SET @LastName = LTRIM(RTRIM(ISNULL(@LastName, N'')))
	SET @SecondLastName = LTRIM(RTRIM(ISNULL(@SecondLastName, N'')))

	SET @FullName = 
	CASE WHEN LEN(@Title) > 0 THEN @Title + ' ' ELSE N'' END + 
	CASE WHEN LEN(@FirstName) > 0 THEN @FirstName + ' ' ELSE N'' END + 
	CASE WHEN LEN(@Initials) > 0 THEN @Initials + ' ' ELSE N'' END + 
	CASE WHEN LEN(@MiddleName) > 0 THEN @MiddleName + ' ' ELSE N'' END + 
	CASE WHEN LEN(@LastName) > 0 THEN @LastName + ' ' ELSE N'' END + 
	CASE WHEN LEN(@SecondLastName) > 0 THEN @SecondLastName + ' ' ELSE N'' END
	
	RETURN LTRIM(RTRIM(ISNULL(@FullName, N'')))

END