CREATE TRIGGER [Party].[TR_U_vwDA_DealerNetworks]
    ON [Party].[vwDA_DealerNetworks]
    INSTEAD OF UPDATE
    AS SET NOCOUNT ON

	--DECLARE LOCAL VARIABLES
	
		DECLARE @CurrentTimestamp DATETIME

	--INITIALISE LOCAL VARIABLES
		
		SET @CurrentTimestamp = CURRENT_TIMESTAMP


	--UPDATE DEALERNETWORKS WHERE THERE IS A GENUINE DEALER NAME CHANGE
	
		UPDATE DN
			SET DN.DealerShortName = i.DealerShortName
		FROM Party.DealerNetworks AS DN
		INNER JOIN inserted AS i ON DN.PartyIDFrom = i.PartyIDFrom
								AND DN.PartyIDTo = i.PartyIDTo
								AND DN.RoleTypeIDFrom = i.RoleTypeIDFrom
								AND DN.RoleTypeIDTo = i.RoleTypeIDTo
								AND DN.DealerShortName <> i.DealerShortName
								
	--UPDATE DEALERNETWORKS WHERE THERE IS A GENUINE DEALER CODE CHANGE
	
		UPDATE DN
			SET DN.DealerCode = i.DealerCode
		FROM Party.DealerNetworks AS DN
		INNER JOIN inserted AS i ON DN.PartyIDFrom = i.PartyIDFrom
								AND DN.PartyIDTo = i.PartyIDTo
								AND DN.RoleTypeIDFrom = i.RoleTypeIDFrom
								AND DN.RoleTypeIDTo = i.RoleTypeIDTo
		INNER JOIN deleted AS d ON DN.DealerCode <> i.DealerCode

	-- INSERT ALL ROWS INTO AUDIT_DEALERNETWORKS

		INSERT INTO Sample_Audit.Audit.DealerNetworks

			(
				AuditItemID 
				, PartyIDFrom 
				, RoleTypeIDFrom 
				, PartyIDTo 
				, RoleTypeIDTo 
				, DealerCode 
				, DealerShortName 
				, FromDate
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
				INNER JOIN Party.DealerNetworks AS DN ON DN.PartyIDFrom = i.PartyIDFrom
													AND DN.PartyIDTo = i.PartyIDTo
													AND DN.RoleTypeIDFrom = i.RoleTypeIDFrom
													AND DN.RoleTypeIDTo = i.RoleTypeIDTo
													AND DN.DealerCode = I.DealerCode
				ORDER BY
					i.AuditItemID


	-- !!!!! DELETE DEALERNETWORK ENTRIES WHERE A THROUGH DATE IS GIVEN. !!!!!

	-- DELETE DEALERNETWORKS ROWS

		DELETE DN
		FROM inserted AS i
		INNER JOIN Party.DealerNetworks AS DN ON DN.PartyIDFrom = i.PartyIDFrom
										AND DN.PartyIDTo = i.PartyIDTo
										AND DN.RoleTypeIDFrom = i.RoleTypeIDFrom
										AND DN.RoleTypeIDTo = i.RoleTypeIDTo
										AND DN.DealerCode = i.DealerCode
		WHERE i.ThroughDate IS NOT NULL	

	-- DELETE PARTYRELATIONSHIPS ROWS

		DELETE PR
		FROM inserted AS i
		INNER JOIN Party.PartyRelationships AS PR ON PR.PartyIDFrom = i.PartyIDFrom
											AND PR.PartyIDTo = i.PartyIDTo
											AND PR.RoleTypeIDFrom = i.RoleTypeIDFrom
											AND PR.RoleTypeIDTo = i.RoleTypeIDTo
		WHERE i.ThroughDate IS NOT NULL	

	-- Insert all terminated relationships and those pertaining to DealerNetworks 
	-- relationships with updated DealerShortName into Audit_PartyRelationships 

	INSERT INTO Sample_Audit.Audit.PartyRelationships

			(
				AuditItemID, 
				PartyIDFrom, 
				RoleTypeIDFrom, 
				PartyIDTo, 
				RoleTypeIDTo, 
				FromDate, 
				ThroughDate, 
				PartyRelationshipTypeID
			)

				SELECT DISTINCT
					i.AuditItemID, 
					i.PartyIDFrom, 
					i.RoleTypeIDFrom, 
					i.PartyIDTo, 
					i.RoleTypeIDTo, 
					i.FromDate, 
					i.ThroughDate, 
					prt.PartyRelationshipTypeID
				FROM inserted AS i
				INNER JOIN deleted AS d ON i.PartyIDFrom = d.PartyIDFrom
										AND i.PartyIDTo = d.PartyIDTo
										AND i.RoleTypeIDFrom = d.RoleTypeIDFrom
										AND i.RoleTypeIDTo = d.RoleTypeIDTo
										AND i.DealerCode = d.DealerCode
				INNER JOIN Party.PartyRelationshipTypes AS prt ON i.RoleTypeIDFrom = prt.RoleTypeIDFrom
															AND i.RoleTypeIDTo = prt.RoleTypeIDTo
															
				WHERE i.ThroughDate IS NOT NULL
				OR (i.DealerShortName <> d.DealerShortName)
				ORDER BY
					i.AuditItemID