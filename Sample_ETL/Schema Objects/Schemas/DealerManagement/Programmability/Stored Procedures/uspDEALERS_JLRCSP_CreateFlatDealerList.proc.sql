CREATE PROCEDURE DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList
AS 


--	Purpose:	Create a table of Dealers with their transfers (if they have one) and all asociated dealer codes on the row
--
--	Version		Date			Developer		Comment
--	1.0			13/07/2012		Martin Riverol	Created
--  1.1			01/05/2013		Martin Riverol	Added OutletCode_GDD to the output
--  1.2			12/12/2014		Peter Doyle		Bug in final INSERT JOIN 
												--LEFT JOIN ContactMechanism.PartyContactMechanisms PCM  change for version 1.2
												--Also add READ UNCOMMITTED
												-- and TRY CATCH
--  1.3			26/02/2015		Chris Ross		BUG 11026 - Add BusinessRegion
--	1.4			12/10/2016		Chris Ross		BUG 13171 - Add in SubNationalTerritory
--	1.5			13/11/2017		Chris Ledger	BUG 14365 - Add in SVODealer & FleetDealer
--	1.6			10/01/2020		Chris Ledger	BUG 15372 - Fix Hard coded references to databases
--	1.7			06/02/2020		Chris Ledger	BUG 16793 - Add in Dealer10DigitCode
--	1.8			13/01/2021		Chris Ledger	Change SMALLDATETIME to DATETIME to avoid error with pre 1900 dates

    BEGIN TRY

        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
        SET NOCOUNT ON


-- CLEAR DOWN FLATTENED DEALER TABLE

        TRUNCATE TABLE DealerManagement.DEALERS_JLRCSP_Flat

-- GET ALL DEALERS

        CREATE TABLE #Dealers
            (
              Manufacturer NVARCHAR(200) ,
              SuperNationalRegion NVARCHAR(200) ,
              BusinessRegion  NVARCHAR(200),			-- v1.3
              Market NVARCHAR(200) ,
              SubNationalTerritory NVARCHAR(200) ,		-- v1.4
              SubNationalRegion NVARCHAR(200) ,
              DealerGroup NVARCHAR(200) ,
              DealerName NVARCHAR(200) ,
              DealerCode NVARCHAR(50) ,
              ManufacturerDealerCode NVARCHAR(50) ,
              OutletPartyID INT ,
              OutletFunction VARCHAR(20) ,
              OutletFunctionID INT ,
              FromDate DATETIME ,					-- V1.8
              ThroughDate DATETIME ,				-- V1.8
              TransferDealerName NVARCHAR(200) ,
              TransferDealerCode NVARCHAR(50) ,
              TransferPartyID INT ,
              PAGCode NVARCHAR(10) ,
              PAGName NVARCHAR(100) ,
              SVODealer BIT,							-- V1.5
              FleetDealer BIT,							-- V1.5
			  Dealer10DigitCode NVARCHAR(10)			-- V1.7
            )


        INSERT  INTO #Dealers
                ( Manufacturer ,
                  SuperNationalRegion ,
                  BusinessRegion,				-- v1.3
                  Market ,
                  SubNationalTerritory ,		-- v1.4
                  SubNationalRegion ,
                  DealerGroup ,
                  DealerName ,
                  DealerCode ,
                  ManufacturerDealerCode ,
                  OutletPartyID ,
                  OutletFunction ,
                  OutletFunctionID ,
                  FromDate ,
                  ThroughDate ,
                  TransferDealerName ,
                  TransferDealerCode ,
                  TransferPartyID ,
                  PAGCode ,
                  PAGName ,
                  SVODealer ,					-- V1.5
                  FleetDealer,					-- V1.5
				  Dealer10DigitCode				-- V1.7
		        )
                SELECT DISTINCT
                        Manufacturer ,
                        SuperNationalRegion ,
                        BusinessRegion,				-- v1.3
                        Market ,
                        SubNationalTerritory,		--v1.4
                        SubNationalRegion ,
                        CombinedDealer AS DealerGroup ,
                        Outlet AS DealerName ,
                        OutletCode AS DealerCode ,
                        OutletSiteCode AS ManufacturerDealerCode ,
                        OutletPartyID ,
                        OutletFunction ,
                        OutletFunctionID ,
                        FromDate ,
                        ThroughDate ,
                        CASE WHEN TransferPartyID = OutletPartyID THEN NULL
                             ELSE TransferDealer
                        END AS TransferDealerName ,
                        CASE WHEN TransferPartyID = OutletPartyID THEN NULL
                             ELSE TransferDealerCode
                        END AS TransferDealerCode ,
                        CASE WHEN TransferPartyID = OutletPartyID THEN NULL
                             ELSE TransferPartyID
                        END AS TransferPartyID ,
                        PAGCode ,
                        PAGName ,
                        SVODealer,			-- V1.5
                        FleetDealer,		-- V1.5
						Dealer10DigitCode	-- V1.7
                FROM    [$(SampleDB)].dbo.DW_JLRCSPDealers
                ORDER BY Manufacturer ,
                        SuperNationalRegion ,
                        Market ,
                        SubNationalRegion ,
                        OutletCode ,
                        Outlet


-- GET THE MATCHING CODES - Manufacturer

        CREATE TABLE #ManufacturerDealerCodes
            (
              OutletPartyID INT ,
              RoleTypeIDFrom INT ,
              ManufacturerDealerCodes NVARCHAR(1000)
            )


        INSERT  INTO #ManufacturerDealerCodes
                ( OutletPartyID ,
                  RoleTypeIDFrom ,
                  ManufacturerDealerCodes
		        )
                SELECT DISTINCT
                        DN.PartyIDFrom AS OutletPartyID ,
                        DN.RoleTypeIDFrom ,
                        dbo.udfGET_DealersCodesForMatching(DN.PartyIDFrom,
                                                           DN.RoleTypeIDFrom,
                                                           DN.RoleTypeIDTo) AS ManufacturerDealerCodes
                FROM    #Dealers D
                        INNER JOIN [$(SampleDB)].Party.DealerNetworks DN ON DN.PartyIDFrom = D.OutletPartyID
                                                              AND DN.RoleTypeIDFrom = D.OutletFunctionID
                WHERE   DN.RoleTypeIDTo = 7
                        AND ISNULL(DN.DealerCode, '') <> ''

-- GET THE MATCHING CODES - Standard

        CREATE TABLE #DealerCodes
            (
              OutletPartyID INT ,
              RoleTypeIDFrom INT ,
              DealerCodes NVARCHAR(1000)
            )


        INSERT  INTO #DealerCodes
                ( OutletPartyID ,
                  RoleTypeIDFrom ,
                  DealerCodes
		        )
                SELECT DISTINCT
                        DN.PartyIDFrom AS OutletPartyID ,
                        DN.RoleTypeIDFrom ,
                        dbo.udfGET_DealersCodesForMatching(DN.PartyIDFrom,
                                                           DN.RoleTypeIDFrom,
                                                           DN.RoleTypeIDTo) AS DealerCodes
                FROM    #Dealers D
                        INNER JOIN [$(SampleDB)].Party.DealerNetworks DN ON DN.PartyIDFrom = D.OutletPartyID
                                                              AND DN.RoleTypeIDFrom = D.OutletFunctionID
                WHERE   DN.RoleTypeIDTo = 19
                        AND ISNULL(DN.DealerCode, '') <> ''


-- RECORD THE DATA

        INSERT  INTO DealerManagement.DEALERS_JLRCSP_Flat    
                ( Manufacturer ,
                  SuperNationalRegion ,
                  BusinessRegion,				-- v1.3
                  Market ,
                  SubNationalTerritory ,		-- v1.4
                  SubNationalRegion ,
                  DealerGroup ,
                  DealerName ,
                  DealerCode ,
                  ManufacturerDealerCode ,
                  OutletPartyID ,
                  OutletFunction ,
                  OutletFunctionID ,
                  FromDate ,
                  ThroughDate ,
                  TransferDealerName ,
                  TransferDealerCode ,
                  TransferPartyID ,
                  DealerCodes ,
                  ManufacturerDealerCodes ,
                  Town ,
                  PAGCode ,
                  PAGName ,
                  SVODealer ,					-- V1.5
                  FleetDealer,					-- V1.5
				  Dealer10DigitCode				-- V1.7
		        )
                SELECT DISTINCT
                        D.Manufacturer ,
                        D.SuperNationalRegion ,
                        D.BusinessRegion,			-- v1.3
                        D.Market ,
                        D.SubNationalTerritory ,	-- v1.4
                        D.SubNationalRegion ,
                        D.DealerGroup ,
                        D.DealerName ,
                        D.DealerCode ,
                        D.ManufacturerDealerCode ,
                        D.OutletPartyID ,
                        D.OutletFunction ,
                        D.OutletFunctionID ,
                        D.FromDate ,
                        D.ThroughDate ,
                        D.TransferDealerName ,
                        D.TransferDealerCode ,
                        D.TransferPartyID ,
                        SDC.DealerCodes ,
                        SMDC.ManufacturerDealerCodes ,
                        PA.Town ,
                        PAGCode ,
                        PAGName ,
                        D.SVODealer ,					-- V1.5
						D.FleetDealer,					-- V1.5
						D.Dealer10DigitCode				-- V1.7
                FROM    #Dealers D
                        LEFT JOIN #DealerCodes SDC ON SDC.OutletPartyID = D.OutletPartyID
                                                      AND SDC.RoleTypeIDFrom = D.OutletFunctionID
                        LEFT JOIN #ManufacturerDealerCodes SMDC ON SMDC.OutletPartyID = D.OutletPartyID
                                                              AND SMDC.RoleTypeIDFrom = D.OutletFunctionID
			--LEFT JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM  change for version 1.2
                        LEFT JOIN ( SELECT  PartyID ,
                                            MAX(PCM.ContactMechanismID) ContactMechanismID
                                    FROM    [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM
                                    GROUP BY PCM.PartyID
                                  ) PCM
                        INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PCM.ContactMechanismID ON PCM.PartyID = D.OutletPartyID
		
		/* v1.1 ADD JLRS GLOBAL DEALER CODE */	
        UPDATE  f
        SET     OutletCode_GDD = D.OutletCode_GDD
        FROM    DealerManagement.DEALERS_JLRCSP_Flat f
                LEFT JOIN ( SELECT DISTINCT
                                    OutletPartyID ,
                                    OutletFunctionID ,
                                    OutletCode_GDD
                            FROM    [$(SampleDB)].dbo.DW_JLRCSPDealers
                          ) D ON f.OutletPartyID = D.OutletPartyID
                                 AND f.OutletFunctionID = D.OutletFunctionID

/* DROP TEMPORARY TABLES */

        DROP TABLE #Dealers
        DROP TABLE #ManufacturerDealerCodes
        DROP TABLE #DealerCodes

    END TRY

    BEGIN CATCH

        EXEC dbo.usp_RethrowError

    END CATCH

