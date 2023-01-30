CREATE PROCEDURE [dbo].[uspGET_ServiceSampleAnalysisData_12MonthRolling_7Years_V2] 
    @RunDate DATE
AS
    
SET XACT_ABORT ON
	SET NOCOUNT OFF

		--DECLARE @RunDate DATE	
		--SET @RunDate = '2015-07-01'


	/* 
		BASED ON THE DATE PASSED IN, CALCULATE THE START DATE AND END DATE RANGES FOR EVENTS 
		
		Example: 

			RUNDATE: 15 APRIL 2013 
			START DATE: 1 APRIL 2008
			END DATE: 31 MARCH 2013
		
			BANDINGS Apr07 - Mar08
			BANDINGS Apr08 - Mar09
			BANDINGS Apr09 - Mar10
			BANDINGS Apr10 - Mar11
			BANDINGS Apr11 - Mar12
			BANDINGS Apr12 - Mar13


	*/


/*
Version		Date				Developer			Comment
2.1			13/5/2015			Peter Doyle			Deal with discrepancies pointed out in bug 7938 
													1./Made EventDateSale Datetime
													2./Changed initial  INSERT  INTO #AfterSaleDataset queries so that 
													  corresponding EventId's added rather than random ones which was occuring previously
3.1			14/07/2015			Chris Ledger		Exclude historic China events from report
3.2			04/01/2016			Chris Ross			BUG 122216 - Exclude China with Response data from report, fix bugs with #Temp (not 
																 existing) and removal of non-valid VINS.
			08/02/2016			Chris Ross					  - Also increased the VIN size from 30 to 40 as one dodgy VIN failing proc.
			09/05/2017			Eddie Thomas		change ' at least 2 events in 37-72MIS' to be 'at least 3 events in 37-84MIS' - this is 1096 days to 2555 days
3.3			18/04/2018			Eddie Thomas		BUG 14629 - Service Retention Report: Increase in Scope. New Markets and Business Regions	

*/



	/* WORK OUT BANDINGS AND PUT THEM IN A TABLE */
	
    CREATE TABLE #EventDateBandings
        (
          ID INT IDENTITY(1, 1) ,
          RunDate DATE ,
          DateFrom DATE ,
          DateTo DATE ,
          YearOfSales CHAR(13)
        )

    INSERT  INTO #EventDateBandings
            ( RunDate ,
              DateFrom ,
              DateTo
            )
            SELECT  @RunDate ,
                    DATEADD(YY, -7, DATEADD(d, -DAY(@RunDate) + 1, @RunDate)) ,
                    DATEADD(YY, -6, DATEADD(d, -DAY(@RunDate), @RunDate))	
		
    INSERT  INTO #EventDateBandings
            ( RunDate ,
              DateFrom ,
              DateTo
            )
            SELECT  @RunDate ,
                    DATEADD(YY, -6, DATEADD(d, -DAY(@RunDate) + 1, @RunDate)) ,
                    DATEADD(YY, -5, DATEADD(d, -DAY(@RunDate), @RunDate))	
				

    INSERT  INTO #EventDateBandings
            ( RunDate ,
              DateFrom ,
              DateTo
            )
            SELECT  @RunDate ,
                    DATEADD(YY, -5, DATEADD(d, -DAY(@RunDate) + 1, @RunDate)) ,
                    DATEADD(YY, -4, DATEADD(d, -DAY(@RunDate), @RunDate))	
				

    INSERT  INTO #EventDateBandings
            ( RunDate ,
              DateFrom ,
              DateTo
            )
            SELECT  @RunDate ,
                    DATEADD(YY, -4, DATEADD(d, -DAY(@RunDate) + 1, @RunDate)) ,
                    DATEADD(YY, -3, DATEADD(d, -DAY(@RunDate), @RunDate))	
				

    INSERT  INTO #EventDateBandings
            ( RunDate ,
              DateFrom ,
              DateTo
            )
            SELECT  @RunDate ,
                    DATEADD(YY, -3, DATEADD(d, -DAY(@RunDate) + 1, @RunDate)) ,
                    DATEADD(YY, -2, DATEADD(d, -DAY(@RunDate), @RunDate))	
				

    INSERT  INTO #EventDateBandings
            ( RunDate ,
              DateFrom ,
              DateTo
            )
            SELECT  @RunDate ,
                    DATEADD(YY, -2, DATEADD(d, -DAY(@RunDate) + 1, @RunDate)) ,
                    DATEADD(YY, -1, DATEADD(d, -DAY(@RunDate), @RunDate))	
				
				
    INSERT  INTO #EventDateBandings
            ( RunDate ,
              DateFrom ,
              DateTo
            )
            SELECT  @RunDate ,
                    DATEADD(yy, -1, DATEADD(d, -DAY(@RunDate) + 1, @RunDate)) ,
                    DATEADD(d, -DAY(@RunDate), @RunDate)
			
	/* GIVE THE BANDINGS A USER FRIENDLY LABEL */		
	
    UPDATE  #EventDateBandings
    SET     YearOfSales = LEFT(DATENAME(M, DateFrom), 3)
            + RIGHT(CAST(YEAR(DateFrom) AS VARCHAR(4)), 2) + ' - '
            + LEFT(DATENAME(M, DateTo), 3)
            + RIGHT(CAST(YEAR(DateTo) AS VARCHAR(4)), 2)


	--COUNTRY ONLY --V3.3
	SELECT CASE 
							WHEN Market = 'Belgium' THEN 'Belgium'
							WHEN DealerTableEquivMarket IS NOT NULL THEN DealerTableEquivMarket
							ELSE Market
				END AS Market	
	INTO	#ReportCountries
	FROM dbo.markets where market in
	('United Kingdom', 'France', 'Germany', 'Spain', 'China', 'Russian Federation'
	,'Japan', 'Netherlands', 'Portugal' ,'Switzerland','Brazil', 'Australia', 'Korea'
	, 'South Africa', 'Austria' ,'Belgium','Czech Republic' ,'Italy', 'Canada'
	, 'United States of America', 'India','Mexico' ,'Taiwan Province of China') 


	--COUNTRY AND REGION	--V3.3
	SELECT CASE 
							WHEN DealerTableEquivMarket IS NOT NULL THEN DealerTableEquivMarket
							ELSE Market
				END AS Market,
				CASE
						WHEN rg.Region = 'North America NSC' THEN 'North America'
						WHEN rg.Region = 'Latin America & Caribbean' THEN 'LACRO'
						WHEN rg.Region = 'Sub Saharan Africa' THEN 'SSA'
						ELSE rg.Region
				END AS Region
	INTO #ReportCountryAndRegion
	FROM dbo.markets ma
	INNER JOIN dbo.Regions rg on  ma.regionId = rg.regionid
	WHERE  Region IN ('European Importers', 'North America NSC', 'MENA', 'Latin America & Caribbean', 'Asia Pacific Importers', 'Sub Saharan Africa')


	/* TEMPORARY TABLE TO HOLD INITIAL DATA SET */

    CREATE TABLE #AfterSaleDataset
        (
          id INT IDENTITY(1, 1) ,
          Manufacturer VARCHAR(10) ,
          VIN VARCHAR(40) ,					-- v3.2
          EventDateSale DATETIME ,
          YearOfSales CHAR(13) ,
          SaleEventID INT ,
          DealerCode NVARCHAR(10) ,
          Model VARCHAR(20) ,
          Market VARCHAR(100) ,
		  Region VARCHAR(100)	,			--v3.3
		  CountryAggregate INT DEFAULT (0),	--v3.3
		  RegionAggregate INT DEFAULT (0),	--v3.3
          [00-12MIS] DATE ,
          [13-24MIS] DATE ,
          [25-36MIS] DATE ,
          [37-48MIS] DATE ,
          [Over48MIS] DATE ,
          [00-15MIS] DATE ,
          [16-30MIS] DATE ,
          [31-45MIS] DATE ,
          [46-60MIS] DATE ,
          [ServiceEventCount36MIS] TINYINT ,
          [ServiceEventCount37-84MIS] TINYINT --,
          CONSTRAINT pk_#AfterSaleDataset PRIMARY KEY CLUSTERED ( id )
        );

		


		/* TEMPORARY TABLE TO EXCLUDE CHINA SERVICE EVENTS FROM 2012-AUGUST 2013*/
		CREATE TABLE #TempChinaRetention
			(
			  EventID INT 
			);
		
		INSERT INTO #TempChinaRetention (EventID)
		SELECT L.MatchedODSEventID AS EventID
		  FROM [Sample_Audit].[dbo].[Files] F
		  JOIN [WebsiteReporting].[dbo].[SampleQualityAndSelectionLogging] L ON L.AuditID = F.AuditID
		  WHERE FileName LIKE '%china%service%'
		  AND FileName NOT LIKE '%retention%'
		  AND actiondate >= '20120101' AND ActionDate < '20130801' 
		  GROUP BY L.MatchedODSEventID		
		

		/* TEMPORARY TABLE TO EXCLUDE CHINA WITH RESPONSE EVENTS   -- v3.2 */
		CREATE TABLE #ChinaWithResponse_Events 
			(	
				EventID BIGINT
			)
			
		INSERT INTO #ChinaWithResponse_Events (EventID)			
		SELECT aebi.EventID FROM Sample_ETL.china.Sales_WithResponses cwr
		INNER JOIN Event.AutomotiveEventBasedInterviews aebi ON aebi.CaseID = cwr.CaseID
		UNION
		SELECT aebi.EventID FROM Sample_ETL.china.Service_WithResponses cwr
		INNER JOIN Event.AutomotiveEventBasedInterviews aebi ON aebi.CaseID = cwr.CaseID



	/* GET THE GERMAN, JAPANESE SALES EVENTS SINCE THE START OF THE EARLIEST SALE EVENT DATE BANDING */
	-- PP: Germany and Japan ONLY as we receive reg date and not event date

		--INSERT INTO #AfterSaleDataset
		
		--	(
		--		VIN
		--		, EventDateSale

		--	)

		--	SELECT DISTINCT 
		--		V.VIN
		--		, MIN(COALESCE(RegistrationDate, EventDate)) AS SalesEventDate
		--	FROM Vehicle.Vehicles V
		--	INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON V.VehicleID = VPRE.VehicleID
		--	INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
		--	INNER JOIN Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
		--	INNER JOIN DBO.DW_JLRCSPDealers DW ON EPR.PartyID = DW.OutletPartyID
		--	INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VPRE.EventID = VRE.EventID
		--	LEFT JOIN Vehicle.Registrations R ON VRE.RegistrationID = R.RegistrationID
		--	--WHERE YEAR(COALESCE(RegistrationDate, EventDate)) > = 2007
		--	WHERE COALESCE(RegistrationDate, EventDate) > = (SELECT MIN(DateFrom) FROM #EventDateBandings)
		--	AND EventTypeID = 1
		--	AND Market IN ( 'germany','japan')
		--	GROUP BY V.VIN;

			--------------------------
    INSERT  INTO #AfterSaleDataset
            ( VIN ,
              EventDateSale ,
              SaleEventID
			)
            SELECT  VIN ,
                    SalesEventDate ,
                    EventID
            FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY VIN ORDER BY EventDate,E.EventID desc ) AS rownos ,
                                V.VIN ,
                                COALESCE(RegistrationDate, EventDate) AS SalesEventDate ,
                                E.EventID
                      FROM      Vehicle.Vehicles V
                                INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON V.VehicleID = VPRE.VehicleID
                                INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
                                INNER JOIN Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
                                INNER JOIN dbo.DW_JLRCSPDealers DW ON EPR.PartyID = DW.OutletPartyID
                                INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VPRE.EventID = VRE.EventID
                                LEFT JOIN Vehicle.Registrations R ON VRE.RegistrationID = R.RegistrationID
                      WHERE     COALESCE(RegistrationDate, EventDate) > = ( SELECT
                                                              MIN(DateFrom)
                                                              FROM
                                                              #EventDateBandings
                                                              )
                                AND EventTypeID = 1
                                AND Market IN ( 'germany', 'japan' )
                    ) AS X
            WHERE   rownos = 1
			--ORDER BY VIN ,
   --                 SalesEventDate ,
   --                 EventID



	/* GET RECORDS FROM THE OTHER MARKETS */

-------------------------
    INSERT  INTO #AfterSaleDataset
            ( VIN ,
              EventDateSale ,
              SaleEventID
			)
            SELECT  VIN ,
                    SalesEventDate ,
                    EventID
            FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY VIN ORDER BY EventDate,E.EventID desc ) AS rownos ,
                                VIN ,
                                EventDate AS SalesEventDate ,
                                VPRE.EventID
                      FROM      Vehicle.Vehicles V
                                INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON V.VehicleID = VPRE.VehicleID
                                INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
                      WHERE     NOT EXISTS ( SELECT 1
                                             FROM   #AfterSaleDataset A
                                             WHERE  V.VIN = A.VIN )
                                AND E.EventDate > = ( SELECT  MIN(DateFrom)
                                                      FROM    #EventDateBandings
                                                    )
                                AND E.EventTypeID = 1
                                AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report

                    ) AS X
            WHERE   rownos = 1
			--ORDER BY VIN ,
   --                 SalesEventDate ,
   --                 EventID

	/* MR: OK, IF THAT IS THE REQUIREMENT */
	--PP: delete invalid VINs (Dave's request)

    DELETE  FROM #AfterSaleDataset
    WHERE   ( VIN NOT LIKE 'SAJ%'
              AND 
              VIN NOT LIKE 'SAL%'
			  AND 
			  VIN NOT LIKE 'L2C%'   -- v3.2
            );


	/* MR: POPULATE THE EVENTID... IMPLICITLY JAPAN AND GERMANY?? */
	-- PP: Japan and Germany only

	--	UPDATE ASA
	--		SET SaleEventID = E.EventID
	--	FROM Event.Events E
	--	INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
	--	INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
	--	INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VPRE.EventID = VRE.EventID
	--	INNER JOIN Vehicle.Registrations R ON VRE.RegistrationID = R.RegistrationID
	--	INNER JOIN #AfterSaleDataset ASA ON V.VIN = ASA.VIN AND COALESCE(E.EventDate, R.RegistrationDate) = ASA.EventDateSale;


	--/* MR: POPULATE THE EVENTID FOR ALL MARKETS. THIS MAY INCLUDE THE GERMAN/JAPANESE DATA THAT HAVE EVENTDATES? 
	--THE CONSTRAINT NEEDS TO BE MORE EXPLICIT  */
	---- PP: All markets

	--	UPDATE ASA
	--			SET SaleEventID = E.EventID
	--	FROM Event.Events E
	--	INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
	--	INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
	--	INNER JOIN #AfterSaleDataset ASA ON V.VIN = ASA.VIN AND E.EventDate = ASA.EventDateSale
	--	WHERE ASA.SaleEventID IS NULL;
		
	/* MR: POPULATE DEALER, MARKET AND MODEL COLUMNS */

	--RETURN

    UPDATE  #AfterSaleDataset
    SET     DealerCode = DW.OutletCode ,
            Market = DW.Market ,
            Manufacturer = DW.Manufacturer
    FROM    DW_JLRCSPDealers DW
            INNER JOIN Event.EventPartyRoles EPR ON DW.OutletPartyID = EPR.PartyID
    WHERE   #AfterSaleDataset.SaleEventID = EPR.EventID;

	

    UPDATE  #AfterSaleDataset
    SET     Model = M.ModelDescription
    FROM    Vehicle.Models M
            INNER JOIN Vehicle.Vehicles V ON M.ModelID = V.ModelID
    WHERE   #AfterSaleDataset.VIN = V.VIN;


	/* MR: POPULATE EVENTDATE ONE WITH EARLIEST EVENT DATE FROM THE LAST 365 DAYS */

    UPDATE  #AfterSaleDataset
    SET     [00-12MIS] = T.EventDate
    FROM    ( SELECT    P.VIN ,
                        MIN(EventDate) AS EventDate
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                       AND DATEDIFF(DAY, EventDateSale, E.EventDate) < = 365
                        AND EventDate > = EventDateSale
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;

	/* MR: POPULATE EVENTDATE TWO WITH EARLIEST EVENT DATE FROM BETWEEN 366 AND 730 DAYS */

    UPDATE  #AfterSaleDataset
    SET     [13-24MIS] = T.EventDate
    FROM    ( SELECT    P.VIN ,
                        MIN(EventDate) AS EventDate
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 366
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 730
                        AND EventDate > = EventDateSale
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;

	/* MR: POPULATE EVENTDATE THREE WITH EARLIEST EVENT DATE FROM BETWEEN 731 AND 1095 DAYS */

    UPDATE  #AfterSaleDataset
    SET     [25-36MIS] = T.EventDate
    FROM    ( SELECT    P.VIN ,
                        MIN(EventDate) AS EventDate
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
 						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 731
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 1095
                        AND EventDate > = EventDateSale
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;

	/* MR: POPULATE EVENTDATE FOUR WITH EARLIEST EVENT DATE FROM BETWEEN 1096 AND 1460 DAYS */

    UPDATE  #AfterSaleDataset
    SET     [37-48MIS] = T.EventDate
    FROM    ( SELECT    P.VIN ,
                        MIN(EventDate) AS EventDate
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 1096
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 1460
                        AND EventDate > = EventDateSale
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;

	/* MR: POPULATE EVENTDATE FIVE WITH EARLIEST EVENT DATE > 1461 */
	

    UPDATE  #AfterSaleDataset
    SET     [Over48MIS] = T.EventDate
    FROM    ( SELECT    P.VIN ,
                        MIN(EventDate) AS EventDate
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 1461
                        AND EventDate > = EventDateSale
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;


		/* MR: POPULATE NEW EVENTDATE ONE WITH EARLIEST EVENT DATE < 456 */

    UPDATE  #AfterSaleDataset
    SET     [00-15MIS] = T.EventDate
    FROM    ( SELECT    P.VIN ,
                        MIN(EventDate) AS EventDate
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) < = 456
                        AND EventDate > = EventDateSale
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;

		/* MR: POPULATE NEW EVENTDATE TWO WITH EARLIEST EVENT DATE BETWEEN 457 AND 912 */

    UPDATE  #AfterSaleDataset
    SET     [16-30MIS] = T.EventDate
    FROM    ( SELECT    P.VIN ,
                        MIN(EventDate) AS EventDate
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 457
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 912
                        AND EventDate > = EventDateSale
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;


		/* MR: POPULATE NEW EVENTDATE THREE WITH EARLIEST EVENT DATE BETWEEN 913 AND 1368 */

    UPDATE  #AfterSaleDataset
    SET     [31-45MIS] = T.EventDate
    FROM    ( SELECT    P.VIN ,
                        MIN(EventDate) AS EventDate
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 913
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 1368
                        AND EventDate > = EventDateSale
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;

		/* MR: POPULATE NEW EVENTDATE FOUR WITH EARLIEST EVENT DATE BETWEEN 1369 AND 1824 */

    UPDATE  #AfterSaleDataset
    SET     [46-60MIS] = T.EventDate
    FROM    ( SELECT    P.VIN ,
                        MIN(EventDate) AS EventDate
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
 						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 1369
                        AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 1824
                        AND EventDate > = EventDateSale
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;


	/* MR: COUNT THE NUMBER OF DISTINCT EVENTS PER VEHICLE IN THE LAST 3 YEARS */


    UPDATE  #AfterSaleDataset
    SET     ServiceEventCount36MIS = T.EventCount
    FROM    ( SELECT    P.VIN ,
                        COUNT(DISTINCT E.EventID) AS EventCount
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
 						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND ( DATEDIFF(DAY, EventDateSale, E.EventDate) > = 0
                              AND DATEDIFF(DAY, EventDateSale, E.EventDate) < = 1095
                            )
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;


	/* MR: COUNT THE NUMBER OF DISTINCT EVENTS PER VEHICLE IN THE LAST 3 TO 6 YEARS */

    UPDATE  #AfterSaleDataset
    SET     [ServiceEventCount37-84MIS] = T.EventCount
    FROM    ( SELECT    P.VIN ,
                        COUNT(DISTINCT E.EventID) AS EventCount
              FROM      Event.Events E
                        INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
                        INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
                        INNER JOIN #AfterSaleDataset P ON V.VIN = P.VIN
              WHERE     EventTypeID IN ( 2 )
						AND E.EventID NOT IN (SELECT EventID FROM #TempChinaRetention)			--V3.1 Exclude historic China events from report
		 				AND E.EventID NOT IN (SELECT EventID FROM #ChinaWithResponse_Events)	--V3.2 Exclude China with Response events from report
                        AND ( DATEDIFF(DAY, EventDateSale, E.EventDate) > = 1096
                              AND DATEDIFF(DAY, EventDateSale, E.EventDate) < = 2555
                            )
              GROUP BY  P.VIN
            ) T
    WHERE   T.VIN = #AfterSaleDataset.VIN;

	--FLAG MARKETS TO APPEAR IN THE REPORT --v3.3
		UPDATE ASD
		SET CountryAggregate = 1
		FROM #AfterSaleDataset ASD
		INNER JOIN #ReportCountries RC ON ASD.Market = RC.Market


		--FLAG THE REGIONS TO APPEAR IN THE REPORT --v3.3
		UPDATE ASD
		SET		RegionAggregate	=  1,								 
					Region						=  RCR.Region
		FROM #AfterSaleDataset ASD
		INNER JOIN #ReportCountryAndRegion RCR ON ASD.Market = RCR.Market

	/* CREATE TABLES TO HOLD THE AGGREGATIONS */

    CREATE TABLE #ServiceRetention_Country	--v3.3
        (
          id INT IDENTITY(1, 1) ,
          Manufacturer VARCHAR(10) ,
          Market VARCHAR(100) ,
          YearOfSales CHAR(13) ,
          NumberOfSales INT ,
          [00-15MIS] INT ,
          [16-30MIS] INT ,
          [31-45MIS] INT ,
          [46-60MIS] INT ,
          [+2Events37-84MIS] INT ,
          [+1Events37-84MIS] INT ,
          CONSTRAINT pk_#ServiceRetention PRIMARY KEY CLUSTERED ( id )
        );

		
		CREATE TABLE #ServiceRetention_Region	--v3.3
		
			(  id INT IDENTITY(1,1),
				Manufacturer varchar(10)
				, Market varchar(100)
				, YearOfSales CHAR(13)
				, NumberOfSales int
				, [00-15MIS] int
				, [16-30MIS] int
				, [31-45MIS] int
				, [46-60MIS] int
				, [+2Events37-84MIS] INT
				, [+1Events37-84MIS] INT
                ,CONSTRAINT pk_#ServiceRetention_Region PRIMARY KEY CLUSTERED (id)
			);


	
	/* POPULATE YEAR OF SALES BASED ON EVENTDATERANGE */

    UPDATE  ASA
    SET     YearOfSales = EDB.YearOfSales
    FROM    #AfterSaleDataset ASA
            INNER JOIN #EventDateBandings EDB ON ASA.EventDateSale >= EDB.DateFrom
                                                 AND ASA.EventDateSale < DATEADD(dd,
                                                              1, EDB.DateTo);
		--INNER JOIN #EventDateBandings EDB ON ASA.EventDateSale >= EDB.DateFrom AND ASA.EventDateSale <= EDB.DateTo;

	
	/* LETS UNPIVOT THE DATA SO WE HAVE THE DATA WE WANT TO PIVOT ON THE ROW --------COUNTRIES--------*/

    WITH    cteServiceRetention ( Manufacturer, Market, YearOfSales, MIS, Banding )
              AS ( SELECT   Manufacturer ,
                            Market ,
                            YearOfSales ,
                            MIS ,
                            Banding
                   FROM     ( SELECT    Manufacturer ,
                                        Market ,
                                        YearOfSales ,
                                        CASE WHEN [00-15MIS] IS NULL THEN 0
                                             ELSE 1
                                        END AS [00-15MIS] ,
                                        CASE WHEN [16-30MIS] IS NULL THEN 0
                                             ELSE 1
                                        END AS [16-30MIS] ,
                                        CASE WHEN [31-45MIS] IS NULL THEN 0
                                             ELSE 1
                                        END AS [31-45MIS] ,
                                        CASE WHEN [46-60MIS] IS NULL THEN 0
                                             ELSE 1
                                        END AS [46-60MIS]
                              FROM      #AfterSaleDataset
							 WHERE CountryAggregate = 1	--v3.3
                            ) T UNPIVOT 
				(
						-- VALUE FOR COLUMNNAMES IN (LIST OF COLUMN NAMES)
                            Banding FOR MIS IN ( [00-15MIS], [16-30MIS],
                                                 [31-45MIS], [46-60MIS] ) ) P
                 )
        INSERT  INTO #ServiceRetention_Country
                ( Manufacturer ,
                  Market ,
                  YearOfSales ,
                  [00-15MIS] ,
                  [16-30MIS] ,
                  [31-45MIS] ,
                  [46-60MIS]
				)
                SELECT  Manufacturer ,
                        Market ,
                        YearOfSales ,
                        [00-15MIS] ,
                        [16-30MIS] ,
                        [31-45MIS] ,
                        [46-60MIS]
                FROM   
						 ( SELECT    Manufacturer ,
                                    Market ,
                                    YearOfSales ,
                                    MIS ,
                                    Banding
                          FROM      cteServiceRetention T
                        ) src 
				PIVOT
						(
								 SUM(Banding) 
								 FOR MIS IN ( [00-15MIS], [16-30MIS], [31-45MIS], [46-60MIS] ) 
						) pvt
                ORDER BY Market , YearOfSales;


	/* LETS UNPIVOT THE DATA SO WE HAVE THE DATA WE WANT TO PIVOT ON THE ROW --------REGION--------*/

		WITH cteServiceRetention (Manufacturer, Market, YearOfSales, MIS, Banding)

		AS
			(
				SELECT Manufacturer, Market, YearOfSales, MIS, Banding
				FROM
				(
					SELECT 
						Manufacturer
						, Region AS Market
						, YearOfSales
						,
						CASE 
							WHEN [00-15MIS] IS NULL THEN 0
							ELSE 1
						END AS [00-15MIS],
						CASE 
							WHEN [16-30MIS] IS NULL THEN 0
							ELSE 1
						END AS [16-30MIS],
						CASE 
							WHEN [31-45MIS] IS NULL THEN 0
							ELSE 1
						END AS [31-45MIS],
						CASE 
							WHEN [46-60MIS] IS NULL THEN 0
							ELSE 1
						END AS [46-60MIS]
					FROM #AfterSaleDataset
					WHERE RegionAggregate = 1	--v3.3
				) T
				UNPIVOT 
				(
						-- VALUE FOR COLUMNNAMES IN (LIST OF COLUMN NAMES)
						Banding FOR MIS IN ([00-15MIS], [16-30MIS], [31-45MIS], [46-60MIS])
				) P
			)
			
			INSERT INTO #ServiceRetention_Region
				
				(
					Manufacturer
					, Market
					, YearOfSales
					, [00-15MIS]
					, [16-30MIS]
					, [31-45MIS]
					, [46-60MIS]
				)

				SELECT Manufacturer, Market, YearOfSales, [00-15MIS], [16-30MIS], [31-45MIS], [46-60MIS]
				FROM 
					(
						SELECT Manufacturer, Market, YearOfSales, MIS, Banding
						FROM cteServiceRetention T
					) src
				PIVOT
					(
						SUM(Banding)
						FOR MIS IN ([00-15MIS], [16-30MIS], [31-45MIS], [46-60MIS])
					) pvt
				ORDER BY Market, YearOfSales;


	/* ADD COUNT OF SALES RECORDS BY MARKET MANUFACTURER --------COUNTRY-------*/

    UPDATE  SR
    SET     NumberOfSales = S.NumberOfSales
    FROM    #ServiceRetention_Country SR
            INNER JOIN ( SELECT Manufacturer ,
                                Market ,
                                YearOfSales ,
                                COUNT(*) NumberOfSales
                         FROM   #AfterSaleDataset
						 WHERE CountryAggregate = 1	--v3.3
                         GROUP BY Manufacturer ,
                                Market ,
                                YearOfSales
                       ) S ON SR.Manufacturer = S.Manufacturer
                              AND SR.Market = S.Market
                              AND SR.YearOfSales = S.YearOfSales;
		
	
	/* ADD COUNT OF VEHICLES WITH +2 SERVICE EVENTS 37MIS AND 84 MIS */	
	
    UPDATE  SR
    SET     [+2Events37-84MIS] = S.[+2Events37-84MIS]
    FROM    #ServiceRetention_Country SR
            INNER JOIN ( SELECT Manufacturer ,
                                Market ,
                                YearOfSales ,
                                COUNT(*) AS [+2Events37-84MIS]
                         FROM   #AfterSaleDataset
                         WHERE	[ServiceEventCount37-84MIS] >= 2 AND
										CountryAggregate = 1
                         GROUP BY Manufacturer ,
                                Market ,
                                YearOfSales
                       ) S ON SR.Manufacturer = S.Manufacturer
                              AND SR.Market = S.Market
                              AND SR.YearOfSales = S.YearOfSales;

	/* ADD COUNT OF VEHICLES WITH +1 SERVICE EVENTS BETWEEN 37MIS AND 84 MIS */	
	
    UPDATE  SR
    SET     [+1Events37-84MIS] = S.[+1Events37-84MIS]
    FROM    #ServiceRetention_Country SR
            INNER JOIN ( SELECT Manufacturer ,
                                Market ,
                                YearOfSales ,
                                COUNT(*) AS [+1Events37-84MIS]
                         FROM   #AfterSaleDataset
                         WHERE	[ServiceEventCount37-84MIS] >= 1 AND
										CountryAggregate = 1
                         GROUP BY Manufacturer ,
                                Market ,
                                YearOfSales
                       ) S ON SR.Manufacturer = S.Manufacturer
                              AND SR.Market = S.Market
                              AND SR.YearOfSales = S.YearOfSales;


/* ADD COUNT OF SALES RECORDS BY MARKET MANUFACTURER --------REGION-------*/
UPDATE  SR
    SET     NumberOfSales = S.NumberOfSales
    FROM    #ServiceRetention_Region SR
            INNER JOIN ( SELECT Manufacturer ,
                                Region As Market ,
                                YearOfSales ,
                                COUNT(*) NumberOfSales
                         FROM   #AfterSaleDataset
						 WHERE RegionAggregate = 1	--v3.3
                         GROUP BY Manufacturer ,
                                Region ,
                                YearOfSales
                       ) S ON SR.Manufacturer = S.Manufacturer
                              AND SR.Market = S.Market
                              AND SR.YearOfSales = S.YearOfSales;
		
	
	/* ADD COUNT OF VEHICLES WITH +2 SERVICE EVENTS WITHIN  37MIS AND 84 MIS */	
	
    UPDATE  SR
    SET     [+2Events37-84MIS] = S.[+2Events37-84MIS]
    FROM    #ServiceRetention_Region SR
            INNER JOIN ( SELECT Manufacturer ,
                                Region As Market ,
                                YearOfSales ,
                                COUNT(*) AS [+2Events37-84MIS]
                         FROM   #AfterSaleDataset
                         WHERE	[ServiceEventCount37-84MIS] >= 2 AND
										RegionAggregate = 1
                         GROUP BY Manufacturer ,
                                Region ,
                                YearOfSales
                       ) S ON SR.Manufacturer = S.Manufacturer
                              AND SR.Market = S.Market
                              AND SR.YearOfSales = S.YearOfSales;

	/* ADD COUNT OF VEHICLES WITH +1 SERVICE EVENTS BETWEEN 37MIS AND 84 MIS */	
	
    UPDATE  SR
    SET     [+1Events37-84MIS] = S.[+1Events37-84MIS]
    FROM    #ServiceRetention_Region SR
            INNER JOIN ( SELECT Manufacturer ,
                                Region As Market ,
                                YearOfSales ,
                                COUNT(*) AS [+1Events37-84MIS]
                         FROM   #AfterSaleDataset
                         WHERE	[ServiceEventCount37-84MIS] >= 1 AND
										RegionAggregate = 1
                         GROUP BY Manufacturer ,
                                Region ,
                                YearOfSales
                       ) S ON SR.Manufacturer = S.Manufacturer
                              AND SR.Market = S.Market
                              AND SR.YearOfSales = S.YearOfSales;



	/* 
		THE DATA HAS GAPS IN IT (E.G. CHINA HAS NO 2007 DATA) THEREFORE WILL HAVE TO CREATE A TABLE TO HOLD THE DATA 
		FOR OUTPUT AND THEN PUSH RELEVANT DATA INTO IT WHERE WE HAVE IT. 
		ITS A HORRID HARD CODED HACK BUT THE DATA SIMPLY DOESN'T SUPPORT WHAT WAS CREATED MANUALLY BY HAND 
	*/

    CREATE TABLE #JLRMISREPORT
        (
          ID INT IDENTITY(1, 1) ,
          Manufacturer VARCHAR(10) ,
          Market VARCHAR(100) ,
		  CountryAggregate int,		--v3.3
		  RegionAggregate int,		--v3.3
          YearOfSales CHAR(13) ,
          NumberOfSales INT ,
          [00-15MIS] INT ,
          [16-30MIS] INT ,
          [31-45MIS] INT ,
          [46-60MIS] INT ,
          [00-15MIS %] VARCHAR(4) ,
          [16-30MIS %] VARCHAR(4) ,
          [31-45MIS %] VARCHAR(4) ,
          [46-60MIS %] VARCHAR(4) ,
          ManufacturerII VARCHAR(10) ,
          MarketII VARCHAR(100) ,
          YearOfSalesII CHAR(13) ,
          NumberOfSalesII INT ,
          [00-15MISII] INT ,
          [16-30MISII] INT ,
          [31-45MISII] INT ,
          [46-60MISII] INT ,
          [00-15MIS %II] VARCHAR(4) ,
          [16-30MIS %II] VARCHAR(4) ,
          [31-45MIS %II] VARCHAR(4) ,
          [46-60MIS %II] VARCHAR(4) ,
          MarketOrder TINYINT
        );
		
	
	
	/* PUT IN THE SEEDING ROWS THE YEAROFSALES IS NOW GOING TO BE DYNAMIC.... BUGGER */

    INSERT  INTO #JLRMISREPORT		------------- COUNTRIES ---------
            ( Manufacturer ,
              Market ,
              YearOfSales ,
              NumberOfSales ,
              [00-15MIS] ,
              [16-30MIS] ,
              [31-45MIS] ,
              [46-60MIS] ,
              [00-15MIS %] ,
              [16-30MIS %] ,
              [31-45MIS %] ,
              [46-60MIS %] ,
              ManufacturerII ,
              MarketII ,
              YearOfSalesII ,
              NumberOfSalesII ,
              [00-15MISII] ,
              [16-30MISII] ,
              [31-45MISII] ,
              [46-60MISII] ,
              [00-15MIS %II] ,
              [16-30MIS %II] ,
              [31-45MIS %II] ,
              [46-60MIS %II] ,
              MarketOrder ,
			  CountryAggregate
		    )
            SELECT DISTINCT
                    A.Manufacturer ,
                    A.Market ,
                    B.YearOfSales ,
                    0 AS NumberOfSales ,
                    0 AS [00-15MIS] ,
                    0 AS [16-30MIS] ,
                    0 AS [31-45MIS] ,
                    0 AS [46-60MIS] ,
                    '0%' AS [00-15MIS %] ,
                    '0%' AS [16-30MIS %] ,
                    '0%' AS [31-45MIS %] ,
                    '0%' AS [46-60MIS %] ,
                    'Jaguar' AS ManufacturerII ,
                    A.Market AS MarketII ,
                    B.YearOfSales AS YearOfSalesII ,
                    0 AS NumberOfSalesII ,
                    0 AS [00-15MISII] ,
                    0 AS [16-30MISII] ,
                    0 AS [31-45MISII] ,
                    0 AS [46-60MISII] ,
                    '0%' AS [00-15MIS %II] ,
                    '0%' AS [16-30MIS %II] ,
                    '0%' AS [31-45MIS %II] ,
                    '0%' AS [46-60MIS %II] ,
                    CASE Market
						WHEN 'UK' THEN 1
						WHEN 'France' THEN 2
						WHEN 'Germany' THEN 3
						WHEN 'Spain' THEN 4
						WHEN 'China' THEN 5
						WHEN 'Russian Federation' THEN 6
						WHEN 'Japan' THEN 7
						WHEN 'Netherlands' THEN 8
						WHEN 'Portugal' THEN 9
						WHEN 'Switzerland' THEN 10
						WHEN 'Brazil' THEN 11
						WHEN 'Australia' THEN 12
						WHEN 'Korea' THEN 13
						WHEN 'South Africa' THEN 14
						WHEN 'Austria' THEN 15
						WHEN 'Belgium' THEN 16
						WHEN 'Czech Republic' THEN 17
						WHEN 'Italy' THEN 18
						WHEN 'Canada' THEN 19
						WHEN 'USA' THEN 20
						WHEN 'India' THEN 21
						WHEN 'Mexico' THEN 22
						WHEN 'Taiwan' THEN 23
			END	MarketOrder
			,CountryAggregate
            FROM				#AfterSaleDataset A
            CROSS JOIN		#EventDateBandings B
            WHERE				A.Manufacturer = 'land rover' And 
									A.CountryAggregate=1
          

		  INSERT  INTO #JLRMISREPORT		------------- REGIONS ---------
            ( Manufacturer ,
              Market ,
              YearOfSales ,
              NumberOfSales ,
              [00-15MIS] ,
              [16-30MIS] ,
              [31-45MIS] ,
              [46-60MIS] ,
              [00-15MIS %] ,
              [16-30MIS %] ,
              [31-45MIS %] ,
              [46-60MIS %] ,
              ManufacturerII ,
              MarketII ,
              YearOfSalesII ,
              NumberOfSalesII ,
              [00-15MISII] ,
              [16-30MISII] ,
              [31-45MISII] ,
              [46-60MISII] ,
              [00-15MIS %II] ,
              [16-30MIS %II] ,
              [31-45MIS %II] ,
              [46-60MIS %II] ,
              MarketOrder ,
			  RegionAggregate
		    )
            SELECT DISTINCT
                    A.Manufacturer ,
                    A.Region As Market,
                    B.YearOfSales ,
                    0 AS NumberOfSales ,
                    0 AS [00-15MIS] ,
                    0 AS [16-30MIS] ,
                    0 AS [31-45MIS] ,
                    0 AS [46-60MIS] ,
                    '0%' AS [00-15MIS %] ,
                    '0%' AS [16-30MIS %] ,
                    '0%' AS [31-45MIS %] ,
                    '0%' AS [46-60MIS %] ,
                    'Jaguar' AS ManufacturerII ,
                    A.Region  AS MarketII ,
                    B.YearOfSales AS YearOfSalesII ,
                    0 AS NumberOfSalesII ,
                    0 AS [00-15MISII] ,
                    0 AS [16-30MISII] ,
                    0 AS [31-45MISII] ,
                    0 AS [46-60MISII] ,
                    '0%' AS [00-15MIS %II] ,
                    '0%' AS [16-30MIS %II] ,
                    '0%' AS [31-45MIS %II] ,
                    '0%' AS [46-60MIS %II] ,
                    CASE Region
							WHEN 'European Importers' THEN 24
							WHEN 'North America' THEN 25
							WHEN 'MENA' THEN 26
							WHEN 'LACRO' THEN 27
							WHEN 'Asia Pacific Importers' THEN 28
							WHEN 'SSA' THEN 29
					END	MarketOrder
					, A.RegionAggregate
            FROM				#AfterSaleDataset A
            CROSS JOIN		#EventDateBandings B
            WHERE				A.Manufacturer = 'land rover' And 
									A.RegionAggregate=1
	

    CREATE TABLE #JLREventsReport
        (
          ID INT IDENTITY(1, 1) ,
          Manufacturer VARCHAR(10) ,
          Market VARCHAR(100) ,
          YearOfSales CHAR(13) ,
          NumberOfSales INT ,
          [+2Events37-84MIS] INT ,
          [+2Events37-84MIS %] VARCHAR(4) ,
          [+1Events37-84MIS] INT ,
          [+1Events37-84MIS %] VARCHAR(4) ,
          ManufacturerII VARCHAR(10) ,
          MarketII VARCHAR(100) ,
          YearOfSalesII CHAR(13) ,
          NumberOfSalesII INT ,
          [+2Events37-84MISII] INT ,
          [+2Events37-84MIS %II] VARCHAR(4) ,
          [+1Events37-84MISII] INT ,
          [+1Events37-84MIS %II] VARCHAR(4) ,
          MarketOrder TINYINT
		  , CountryAggregate int
		  , RegionAggregate int
        );

    INSERT  INTO #JLREventsReport			----------COUNTRIES----------
            ( Manufacturer ,
              Market ,
              YearOfSales ,
              NumberOfSales ,
              [+2Events37-84MIS] ,
              [+2Events37-84MIS %] ,
              [+1Events37-84MIS] ,
              [+1Events37-84MIS %] ,
              ManufacturerII ,
              MarketII ,
              YearOfSalesII ,
              NumberOfSalesII ,
              [+2Events37-84MISII] ,
              [+2Events37-84MIS %II] ,
              [+1Events37-84MISII] ,
              [+1Events37-84MIS %II] ,
              MarketOrder,
			  CountryAggregate
            )
            SELECT DISTINCT
                    A.Manufacturer ,
                    A.Market ,
                    B.YearOfSales ,
                    0 AS NumberOfSales ,
                    0 AS [+2Events37-84MIS] ,
                    '0%' AS [+2Events37-84MIS %] ,
                    0 AS [+1Events37-84MIS] ,
                    '0%' AS [+1Events37-84MIS %] ,
                    'Jaguar' AS ManufacturerII ,
                    A.Market AS MarketII ,
                    B.YearOfSales AS YearOfSalesII ,
                    0 AS NumberOfSales ,
                    0 AS [+2Events37-84MIS] ,
                    '0%' AS [+2Events37-84MIS %] ,
                    0 AS [+1Events37-84MIS] ,
                    '0%' AS [+1Events37-84MIS %] ,
                    CASE A.Market
						WHEN 'UK' THEN 1
						WHEN 'France' THEN 2
						WHEN 'Germany' THEN 3
						WHEN 'Spain' THEN 4
						WHEN 'China' THEN 5
						WHEN 'Russian Federation' THEN 6
						WHEN 'Japan' THEN 7
						WHEN 'Netherlands' THEN 8
						WHEN 'Portugal' THEN 9
						WHEN 'Switzerland' THEN 10
						WHEN 'Brazil' THEN 11
						WHEN 'Australia' THEN 12
						WHEN 'Korea' THEN 13
						WHEN 'South Africa' THEN 14
						WHEN 'Austria' THEN 15
						WHEN 'Belgium' THEN 16
						WHEN 'Czech Republic' THEN 17
						WHEN 'Italy' THEN 18
						WHEN 'Canada' THEN 19
						WHEN 'USA' THEN 20
						WHEN 'India' THEN 21
						WHEN 'Mexico' THEN 22
						WHEN'Taiwan' THEN 23				
					END	MarketOrder
				, A.CountryAggregate
            FROM			#AfterSaleDataset A
            CROSS JOIN #EventDateBandings B
            WHERE			Manufacturer = 'land rover' AND
								A.CountryAggregate =1

			

			INSERT  INTO #JLREventsReport			----------REGIONS----------
            ( Manufacturer ,
              Market ,
              YearOfSales ,
              NumberOfSales ,
              [+2Events37-84MIS] ,
              [+2Events37-84MIS %] ,
              [+1Events37-84MIS] ,
              [+1Events37-84MIS %] ,
              ManufacturerII ,
              MarketII ,
              YearOfSalesII ,
              NumberOfSalesII ,
              [+2Events37-84MISII] ,
              [+2Events37-84MIS %II] ,
              [+1Events37-84MISII] ,
              [+1Events37-84MIS %II] ,
              MarketOrder,
			  RegionAggregate
            )
            SELECT DISTINCT
                    A.Manufacturer ,
                    A.Region As Market ,
                    B.YearOfSales ,
                    0 AS NumberOfSales ,
                    0 AS [+2Events37-84MIS] ,
                    '0%' AS [+2Events37-84MIS %] ,
                    0 AS [+1Events37-84MIS] ,
                    '0%' AS [+1Events37-84MIS %] ,
                    'Jaguar' AS ManufacturerII ,
                    A.Region  AS MarketII ,
                    B.YearOfSales AS YearOfSalesII ,
                    0 AS NumberOfSales ,
                    0 AS [+2Events37-84MIS] ,
                    '0%' AS [+2Events37-84MIS %] ,
                    0 AS [+1Events37-84MIS] ,
                    '0%' AS [+1Events37-84MIS %] ,
                    CASE Region
							WHEN 'European Importers' THEN 24
							WHEN 'North America' THEN 25
							WHEN 'MENA' THEN 26
							WHEN 'LACRO' THEN 27
							WHEN 'Asia Pacific Importers' THEN 28
							WHEN 'SSA' THEN 29
					 END	MarketOrder
					, A.RegionAggregate
            FROM			#AfterSaleDataset A
            CROSS JOIN #EventDateBandings B
            WHERE			Manufacturer = 'land rover' AND
								A.RegionAggregate =1





	/* RETURN JLR SERVICE RETENTION BY MARKET / MIS */
		
		-- ADD LAND ROVER AGGREGATIONS
--select * from #JLREventsReport
--select * from #ServiceRetention

	--------- COUNTRIES ---------
    UPDATE  R
    SET     NumberOfSales = SR.NumberOfSales ,
            [00-15MIS] = SR.[00-15MIS] ,
            [16-30MIS] = SR.[16-30MIS] ,
            [31-45MIS] = SR.[31-45MIS] ,
            [46-60MIS] = SR.[46-60MIS] ,
            [00-15MIS %] = CAST(CAST(ROUND(( CAST(SR.[00-15MIS] AS DECIMAL(10,
                                                              2))
                                             / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [16-30MIS %] = CAST(CAST(ROUND(( CAST(SR.[16-30MIS] AS DECIMAL(10,
                                                              2))
                                             / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [31-45MIS %] = CAST(CAST(ROUND(( CAST(SR.[31-45MIS] AS DECIMAL(10,
                                                              2))
                                             / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [46-60MIS %] = CAST(CAST(ROUND(( CAST(SR.[46-60MIS] AS DECIMAL(10,
                                                              2))
                                             / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%'
    FROM    #ServiceRetention_Country SR
            INNER JOIN #JLRMISREPORT R ON SR.Manufacturer = R.Manufacturer
                                          AND SR.Market = R.Market
                                          AND SR.YearOfSales = R.YearOfSales
    WHERE		R.CountryAggregate =1
					AND SR.Manufacturer = 'Land Rover'


	--------- REGIONS ---------
    UPDATE  R
    SET     NumberOfSales = SR.NumberOfSales ,
            [00-15MIS] = SR.[00-15MIS] ,
            [16-30MIS] = SR.[16-30MIS] ,
            [31-45MIS] = SR.[31-45MIS] ,
            [46-60MIS] = SR.[46-60MIS] ,
            [00-15MIS %] = CAST(CAST(ROUND(( CAST(SR.[00-15MIS] AS DECIMAL(10,
                                                              2))
                                             / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [16-30MIS %] = CAST(CAST(ROUND(( CAST(SR.[16-30MIS] AS DECIMAL(10,
                                                              2))
                                             / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [31-45MIS %] = CAST(CAST(ROUND(( CAST(SR.[31-45MIS] AS DECIMAL(10,
                                                              2))
                                             / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [46-60MIS %] = CAST(CAST(ROUND(( CAST(SR.[46-60MIS] AS DECIMAL(10,
                                                              2))
                                             / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%'
    FROM    #ServiceRetention_Region SR
    INNER JOIN #JLRMISREPORT R ON SR.Manufacturer = R.Manufacturer
                                          AND SR.Market = R.Market
                                          AND SR.YearOfSales = R.YearOfSales
    WHERE		R.RegionAggregate =1
					AND SR.Manufacturer = 'Land Rover'



		-- ADD JAGUAR AGGREGATIONS
		--------- COUNTRIES ---------
    UPDATE  R
    SET     NumberOfSalesII = SR.NumberOfSales ,
            [00-15MISII] = SR.[00-15MIS] ,
            [16-30MISII] = SR.[16-30MIS] ,
            [31-45MISII] = SR.[31-45MIS] ,
            [46-60MISII] = SR.[46-60MIS] ,
            [00-15MIS %II] = CAST(CAST(ROUND(( CAST(SR.[00-15MIS] AS DECIMAL(10,
                                                              2))
                                               / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [16-30MIS %II] = CAST(CAST(ROUND(( CAST(SR.[16-30MIS] AS DECIMAL(10,
                                                              2))
                                               / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [31-45MIS %II] = CAST(CAST(ROUND(( CAST(SR.[31-45MIS] AS DECIMAL(10,
                                                              2))
                                               / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [46-60MIS %II] = CAST(CAST(ROUND(( CAST(SR.[46-60MIS] AS DECIMAL(10,
                                                              2))
                                               / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%'
    FROM    #ServiceRetention_Country SR
    INNER JOIN #JLRMISREPORT R ON SR.Manufacturer = R.ManufacturerII
                                          AND SR.Market = R.MarketII
                                          AND SR.YearOfSales = R.YearOfSalesII
    WHERE		R.CountryAggregate =1
					AND SR.Manufacturer = 'Jaguar'

	--------- REGIONS ---------
	UPDATE  R
    SET     NumberOfSalesII = SR.NumberOfSales ,
            [00-15MISII] = SR.[00-15MIS] ,
            [16-30MISII] = SR.[16-30MIS] ,
            [31-45MISII] = SR.[31-45MIS] ,
            [46-60MISII] = SR.[46-60MIS] ,
            [00-15MIS %II] = CAST(CAST(ROUND(( CAST(SR.[00-15MIS] AS DECIMAL(10,
                                                              2))
                                               / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [16-30MIS %II] = CAST(CAST(ROUND(( CAST(SR.[16-30MIS] AS DECIMAL(10,
                                                              2))
                                               / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [31-45MIS %II] = CAST(CAST(ROUND(( CAST(SR.[31-45MIS] AS DECIMAL(10,
                                                              2))
                                               / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [46-60MIS %II] = CAST(CAST(ROUND(( CAST(SR.[46-60MIS] AS DECIMAL(10,
                                                              2))
                                               / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%'
    FROM    #ServiceRetention_Region SR
    INNER JOIN #JLRMISREPORT R ON SR.Manufacturer = R.ManufacturerII
                                          AND SR.Market = R.MarketII
                                          AND SR.YearOfSales = R.YearOfSalesII
    WHERE		R.RegionAggregate =1
					AND SR.Manufacturer = 'Jaguar'

		--- RETURN DATA SET
    SELECT  [Manufacturer] ,
            [Market] ,
            [YearOfSales] ,
            [NumberOfSales] ,
            [00-15MIS] ,
            [16-30MIS] ,
            [31-45MIS] ,
            [46-60MIS] ,
            [00-15MIS %] ,
            [16-30MIS %] ,
            [31-45MIS %] ,
            [46-60MIS %] ,
            [ManufacturerII] AS [Manufacturer] ,
            [MarketII] AS [Market] ,
            [YearOfSalesII] AS [YearOfSales] ,
            [NumberOfSalesII] AS [NumberOfSales] ,
            [00-15MISII] AS [00-15MIS] ,
            [16-30MISII] AS [16-30MIS] ,
            [31-45MISII] AS [31-45MIS] ,
            [46-60MISII] AS [46-60MIS] ,
            [00-15MIS %II] AS [00-15MIS %] ,
            [16-30MIS %II] AS [16-30MIS %] ,
            [31-45MIS %II] AS [31-45MIS %] ,
            [46-60MIS %II] AS [46-60MIS %]
    FROM    #JLRMISREPORT
    ORDER BY MarketOrder ,  YearOfSalesII

	/* RETURN JLR SERVICE RETENTION 2 + SERVICE EVENTS WITHIN 36 MIS */
	--------- COUNTRIES ---------
    UPDATE  R
    SET     NumberOfSales = sr.NumberOfSales ,
            [+2Events37-84MIS] = sr.[+2Events37-84MIS] ,
            [+2Events37-84MIS %] = CAST(CAST(ROUND(( CAST(sr.[+2Events37-84MIS] AS DECIMAL(10,
                                                              2))
                                                  / CAST(sr.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [+1Events37-84MIS] = sr.[+1Events37-84MIS] ,
            [+1Events37-84MIS %] = CAST(CAST(ROUND(( CAST(sr.[+1Events37-84MIS] AS DECIMAL(10,
                                                              2))
                                                     / CAST(sr.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%'
    FROM    #ServiceRetention_Country sr
            INNER JOIN #JLREventsReport R ON sr.Manufacturer = R.Manufacturer
                                             AND sr.Market = R.Market
                                             AND sr.YearOfSales = R.YearOfSales
    WHERE		R.CountryAggregate =1
					AND sr.Manufacturer = 'Land Rover'
		

	--------- REGIONS ---------
    UPDATE  R
    SET     NumberOfSales = sr.NumberOfSales ,
            [+2Events37-84MIS] = sr.[+2Events37-84MIS] ,
            [+2Events37-84MIS %] = CAST(CAST(ROUND(( CAST(sr.[+2Events37-84MIS] AS DECIMAL(10,
                                                              2))
                                                  / CAST(sr.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [+1Events37-84MIS] = sr.[+1Events37-84MIS] ,
            [+1Events37-84MIS %] = CAST(CAST(ROUND(( CAST(sr.[+1Events37-84MIS] AS DECIMAL(10,
                                                              2))
                                                     / CAST(sr.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%'
    FROM    #ServiceRetention_Region sr
            INNER JOIN #JLREventsReport R ON sr.Manufacturer = R.Manufacturer
                                             AND sr.Market = R.Market
                                             AND sr.YearOfSales = R.YearOfSales
    WHERE		R.RegionAggregate =1
					AND sr.Manufacturer = 'Land Rover'
		


	--------- COUNTRIES ---------
    UPDATE  R
    SET     NumberOfSalesII = SR.NumberOfSales ,
            [+2Events37-84MISII] = SR.[+2Events37-84MIS] ,
            [+2Events37-84MIS %II] = CAST(CAST(ROUND(( CAST(SR.[+2Events37-84MIS] AS DECIMAL(10,
                                                              2))
                                                    / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [+1Events37-84MISII] = SR.[+1Events37-84MIS] ,
            [+1Events37-84MIS %II] = CAST(CAST(ROUND(( CAST(SR.[+1Events37-84MIS] AS DECIMAL(10,
                                                              2))
                                                       / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%'
    FROM    #ServiceRetention_Country SR
            INNER JOIN #JLREventsReport R ON SR.Manufacturer = R.ManufacturerII
                                             AND SR.Market = R.MarketII
                                             AND SR.YearOfSales = R.YearOfSalesII
    WHERE		R.CountryAggregate =1
					AND SR.Manufacturer = 'Jaguar'


	--------- REGIONS ---------
    UPDATE  R
    SET     NumberOfSalesII = SR.NumberOfSales ,
            [+2Events37-84MISII] = SR.[+2Events37-84MIS] ,
            [+2Events37-84MIS %II] = CAST(CAST(ROUND(( CAST(SR.[+2Events37-84MIS] AS DECIMAL(10,
                                                              2))
                                                    / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%' ,
            [+1Events37-84MISII] = SR.[+1Events37-84MIS] ,
            [+1Events37-84MIS %II] = CAST(CAST(ROUND(( CAST(SR.[+1Events37-84MIS] AS DECIMAL(10,
                                                              2))
                                                       / CAST(SR.NumberOfSales AS DECIMAL(10,
                                                              2)) ) * 100, 0) AS INT) AS VARCHAR(5))
            + '%'
    FROM    #ServiceRetention_Region SR
            INNER JOIN #JLREventsReport R ON SR.Manufacturer = R.ManufacturerII
                                             AND SR.Market = R.MarketII
                                             AND SR.YearOfSales = R.YearOfSalesII
    WHERE		R.RegionAggregate =1
					AND SR.Manufacturer = 'Jaguar'


    SELECT  [Manufacturer] ,
            [Market] ,
            [YearOfSales] ,
            [NumberOfSales] ,
            ISNULL([+2Events37-84MIS], 0) AS [+2Events37-84MIS] ,
            ISNULL([+2Events37-84MIS %], '0%') AS [+2Events37-84MIS %] ,
            ISNULL([+1Events37-84MIS], 0) AS [+1Events37-84MIS] ,
            ISNULL([+1Events37-84MIS %], '0%') AS [+1Events37-84MIS %] ,
            [ManufacturerII] AS Manufacturer ,
            [MarketII] AS Market ,
            [YearOfSalesII] AS YearOfSales ,
            [NumberOfSalesII] AS NumberOfSales ,
            ISNULL([+2Events37-84MISII], 0) AS [+2Events37-84MIS] ,
            ISNULL([+2Events37-84MIS %II], '0%') AS [+2Events37-84MIS %] ,
            ISNULL([+1Events37-84MISII], 0) AS [+1Events37-84MIS] ,
            ISNULL([+1Events37-84MIS %II], '0%') AS [+1Events37-84MIS %]
    FROM    #JLREventsReport
    ORDER BY MarketOrder , YearOfSalesII


