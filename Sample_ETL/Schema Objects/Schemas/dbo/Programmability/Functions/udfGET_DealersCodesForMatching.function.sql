CREATE FUNCTION [dbo].[udfGET_DealersCodesForMatching]
(
	 @DealerPartyID INT
	,@RoleTypeIDFrom INT
	,@RoleTypeIDTo INT
) 
RETURNS NVARCHAR(1000)
AS

/*
	Purpose:	Gets all dealer codes for a given DealerPartyID and RoleTypeID (sales or service) and concatenates them with commas
	
	Version			Date			Developer			Comment
	1.0				13/07/2012		Simon Peacock		Created for use in the MS Access dealer database
	1.1				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

BEGIN

	DECLARE @DealerCodes TABLE (ID INT IDENTITY(1,1), PartyIDFrom INT, DealerCode NVARCHAR(255))

	INSERT INTO @DealerCodes
	SELECT DISTINCT PartyIDFrom, DealerCode
	FROM [$(SampleDB)].Party.DealerNetworks
	WHERE PartyIDFrom = @DealerPartyID
	AND RoleTypeIDFrom = @RoleTypeIDFrom
	AND RoleTypeIDTo = @RoleTypeIDTo
	AND ISNULL(DealerCode, '') <> ''

	DECLARE @Counter INT
	DECLARE @Codes NVARCHAR(1000)

	SELECT @Counter = 1
	SET @Codes = ''

	WHILE @Counter < =(SELECT MAX(ID) FROM @DealerCodes)
	BEGIN

		SELECT @Codes = @Codes + DealerCode + ', '
		FROM @DealerCodes
		WHERE ID = @Counter

		SET @Counter = @Counter + 1

	END

	RETURN LEFT(@Codes, LEN(@Codes) - 1)

END