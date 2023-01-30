CREATE TRIGGER [Party].[TR_I_vwDA_DealerNetworks] ON [Party].[vwDA_DealerNetworks]

INSTEAD OF INSERT

AS

	--	Purpose:		Handles insert into vwDA_DealerNetworks.
	--					N.B. by default inserts into :Industry Classifications with PartyTypeID = 2 (Automotive Industry)
	--
	--	Version		Date			Developer			Comment
	--	1.0			25/04/2012		Martin Riverol		Created
	--  1.1			28/01/2020		Chris Ross			BUG 16810 - Add in default PartyExclusionCategoryID value to IndustryClassification view update.

	
	--DISABLE COUNTS
	SET NOCOUNT ON

	--DECLARE LOCAL VARIABLES
	DECLARE @CurrentTimestamp DATETIME

	--INITIALISE LOCAL VARIABLES
	SET @CurrentTimestamp = CURRENT_TIMESTAMP

	
	-- USE UNION TO INSERT ALL REQUIRED ROLES AND PARTIES INTO VWDA_PARTYROLES BEFORE RELATIONSHIPS ARE CREATED
	INSERT INTO Party.vwDA_PartyRoles

		(
			AuditItemID
			, PartyID
			, RoleTypeID
			, FromDate
		)
			SELECT
				i.AuditItemID
				, i.PartyIDFrom 
				, i.RoleTypeIDFrom 
				, i.FromDate
			FROM inserted AS i
			UNION
			SELECT
				i.AuditItemID 
				, i.PartyIDTo 
				, i.RoleTypeIDTo
				, i.FromDate
			FROM
				inserted AS i
			ORDER BY
				i.AuditItemID


	-- INSERT INTO VWDA_PARTYRELATIONSHIPS
	INSERT INTO Party.vwDA_PartyRelationships
	
		(
			AuditItemID 
			, PartyIDFrom
			, RoleTypeIDFrom 
			, PartyIDTo 
			, RoleTypeIDTo 	
			, FromDate 
			, ThroughDate 
			, PartyRelationshipTypeID 

		)

			SELECT
				i.AuditItemID 
				, i.PartyIDFrom
				, i.RoleTypeIDFrom 
				, i.PartyIDTo 
				, i.RoleTypeIDTo 	
				, COALESCE(i.FromDate, @CurrentTimestamp) 
				, i.ThroughDate 
				, PRT.PartyRelationshipTypeID 
			FROM inserted AS i
			INNER JOIN Party.PartyRelationshipTypes AS PRT ON PRT.RoleTypeIDFrom = i.RoleTypeIDFrom
														AND PRT.RoleTypeIDTo = i.RoleTypeIDTo
			ORDER BY
				i.AuditItemID


	--INSERT INTO DEALERNETWORKS
	INSERT INTO Party.DealerNetworks
	
		(
			PartyIDFrom, 
			RoleTypeIDFrom, 
			PartyIDTo, 
			RoleTypeIDTo, 
			DealerCode, 
			DealerShortName, 
			FromDate
		)

			SELECT DISTINCT
				PR.PartyIDFrom, 
				PR.RoleTypeIDFrom, 
				PR.PartyIDTo, 
				PR.RoleTypeIDTo, 
				i.DealerCode, 
				i.DealerShortName, 
				PR.FromDate
			FROM inserted AS i
			INNER JOIN Party.PartyRelationships AS PR ON PR.PartyIDFrom = i.PartyIDFrom
														AND PR.RoleTypeIDFrom = i.RoleTypeIDFrom
														AND PR.PartyIDTo = i.PartyIDTo
														AND PR.RoleTypeIDTo = i.RoleTypeIDTo
			LEFT JOIN Party.DealerNetworks AS DN ON DN.PartyIDFrom = i.PartyIDFrom
													AND DN.PartyIDTo = i.PartyIDTo
													AND DN.RoleTypeIDFrom = i.RoleTypeIDFrom
													AND DN.RoleTypeIDTo = i.RoleTypeIDTo
			WHERE DN.PartyIDFrom IS NULL
			AND i.ThroughDate IS NULL

	
	-- INSERT INDUSTRY CLASSIFICATIONS
			
			-- Get the relevant exclusion categories			-- v1.1
			DECLARE @BarredExclusionCategoryID INT,
					@BodyshopExclusionCategoryID INT

			SELECT @BarredExclusionCategoryID = PartyExclusionCategoryID 
							from Party.PartyExclusionCategories 
							where ExclusionCategoryName = 'JLR Exclusion - Barred Company'

			SELECT @BodyshopExclusionCategoryID = PartyExclusionCategoryID 
							from Party.PartyExclusionCategories 
							where ExclusionCategoryName = 'JLR Exclusion - Body shop'


			-- do the insert
			INSERT INTO Sample.Party.vwDA_IndustryClassifications

				(
					AuditItemID
					, PartyTypeID
					, PartyExclusionCategoryID			-- v1.1
					, PartyID
					, FromDate
					, ThroughDate 
				)

					SELECT DISTINCT
						i.AuditItemID 
						, 2 AS PartyTypeID --Automotive Industry 
						, CASE WHEN rt.RoleType = 'Authorised Dealer (Bodyshop)' 
								THEN @BodyshopExclusionCategoryID
								ELSE @BarredExclusionCategoryID
							END AS  PartyExclusionCategoryID		-- v1.1
						  , i.PartyIDFrom 
						, i.FromDate
						, i.ThroughDate
					FROM inserted AS i
					LEFT JOIN dbo.RoleTypes rt ON rt.RoleTypeID = i.RoleTypeIDFrom		-- v1.1
		
	-- INSERT ALL ROWS INTO AUDIT_DEALERNETWORKS (INCLUDING DUPES AND THOSE MATCHED EARLIER)

		INSERT INTO Sample_Audit.Audit.DealerNetworks

			(
				AuditItemID, 
				PartyIDFrom, 
				RoleTypeIDFrom, 
				PartyIDTo, 
				RoleTypeIDTo, 
				DealerCode, 
				DealerShortName, 
				FromDate
			)

				SELECT DISTINCT
					i.AuditItemID 
					, i.PartyIDFrom 
					, i.RoleTypeIDFrom 
					, i.PartyIDTo 
					, i.RoleTypeIDTo 
					, i.DealerCode 
					, i.DealerShortName 
					, dn.FromDate
				FROM inserted AS i
				INNER JOIN Sample.party.DealerNetworks AS DN ON DN.PartyIDFrom = i.PartyIDFrom
															AND DN.PartyIDTo = i.PartyIDTo
															AND DN.RoleTypeIDFrom = i.RoleTypeIDFrom
															AND DN.RoleTypeIDTo = i.RoleTypeIDTo
				ORDER BY
					i.AuditItemID