CREATE FUNCTION CRM.Return_BP_Role_IndClass (@ACCT_BP_ROLE varchar(512))
RETURNS int
AS
BEGIN
	
	-- Set variables
	DECLARE @TranslatedRoleIndClass int, @seperator char(1), @FleetIndClass INT
	SET @seperator = '|'

	SELECT @FleetIndClass = PartyTypeID FROM [$(SampleDB)].Party.PartyTypes WHERE PartyType = 'Vehicle Leasing Company'


	--- Get the Roles in the string
	;WITH BP_Roles(pn, start, stop) AS (
      SELECT 1, 1, CHARINDEX(@seperator, @ACCT_BP_ROLE)
      UNION ALL
      SELECT pn + 1, stop + 1, CHARINDEX(@seperator, @ACCT_BP_ROLE, stop + 1)
      FROM BP_Roles
      WHERE stop > 0
    )
    ,BP_Roles_Split
	AS (
		SELECT pn,
		  SUBSTRING(@ACCT_BP_ROLE, start, CASE WHEN stop > 0 THEN stop-start ELSE 512 END) AS RoleCode
		FROM BP_Roles
	)
	
	-- Return the Industry Classification based on the Roles
	SELECT @TranslatedRoleIndClass = CASE WHEN EXISTS (SELECT * FROM BP_Roles_Split WHERE RoleCode = 'ZFACC') THEN @FleetIndClass ELSE 0 END
	RETURN @TranslatedRoleIndClass

END