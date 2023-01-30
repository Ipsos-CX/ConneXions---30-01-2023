CREATE PROCEDURE [dbo].[uspGET_ServiceSampleAnalysisData_12MonthRolling_7Years_ExclWarranty]

		@RunDate DATE

AS

	/*
		Purpose:	Pass back Service retention analyis dataset
		
		Version		Date			Developer			Comment
		1.0			11/04/2013		Martin Riverol		Created
		1.1			19/02/2014		Martin Riverol		Added Australia, Korea, South Africa
		1.2			28/03/2014		Martin Riverol		Remove Event driven service records if we got a warranty 
														claim on the same day
		1.3			20/01/2020		Chris Ledger		Bug 15372 - Fix database references
	*/


	/* SET LOCAL CONNECTION VARIABLES */
	
		SET XACT_ABORT ON
		SET NOCOUNT ON

		-- DECLARE @RunDate DATE	
		-- SET @RunDate = '8 november 2013'


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


	/* WORK OUT BANDINGS AND PUT THEM IN A TABLE */
	
		CREATE TABLE #EventDateBandings

			(
				ID INT IDENTITY(1,1)
				, RunDate DATE
				, DateFrom DATE
				, DateTo DATE
				, YearOfSales VARCHAR(20)
			)

		INSERT INTO #EventDateBandings (RunDate, DateFrom, DateTo) 	

			SELECT 
				@RunDate
				, DATEADD(YY, -7, DATEADD(d, -DAY(@RunDate) + 1, @RunDate))		
				, DATEADD(YY, -6, DATEADD(d, -DAY(@RunDate), @RunDate))	
		
		INSERT INTO #EventDateBandings (RunDate, DateFrom, DateTo) 	

			SELECT 
				@RunDate
				, DATEADD(YY, -6, DATEADD(d, -DAY(@RunDate) + 1, @RunDate))		
				, DATEADD(YY, -5, DATEADD(d, -DAY(@RunDate), @RunDate))	
				

		INSERT INTO #EventDateBandings (RunDate, DateFrom, DateTo) 	

			SELECT 
				@RunDate
				, DATEADD(YY, -5, DATEADD(d, -DAY(@RunDate) + 1, @RunDate))		
				, DATEADD(YY, -4, DATEADD(d, -DAY(@RunDate), @RunDate))	
				

		INSERT INTO #EventDateBandings (RunDate, DateFrom, DateTo) 	

			SELECT 
				@RunDate
				, DATEADD(YY, -4, DATEADD(d, -DAY(@RunDate) + 1, @RunDate))		

				, DATEADD(YY, -3, DATEADD(d, -DAY(@RunDate), @RunDate))	
				

		INSERT INTO #EventDateBandings (RunDate, DateFrom, DateTo) 	

			SELECT 
				@RunDate
				, DATEADD(YY, -3, DATEADD(d, -DAY(@RunDate) + 1, @RunDate))		
				, DATEADD(YY, -2, DATEADD(d, -DAY(@RunDate), @RunDate))	
				

		INSERT INTO #EventDateBandings (RunDate, DateFrom, DateTo) 	

			SELECT 
				@RunDate
				, DATEADD(YY, -2, DATEADD(d, -DAY(@RunDate) + 1, @RunDate))		
				, DATEADD(YY, -1, DATEADD(d, -DAY(@RunDate), @RunDate))	
				
				
		INSERT INTO #EventDateBandings (RunDate, DateFrom, DateTo) 	

			SELECT 
				@rundate
				, DATEADD(yy, -1, DATEADD(d, -DAY(@RunDate) + 1, @RunDate))
				, DATEADD(d, -day(@RunDate), @RunDate)
			
	/* GIVE THE BANDINGS A USER FRIENDLY LABEL */		
	
		UPDATE #EventDateBandings
			SET YearOfSales = LEFT(DATENAME(M, DateFrom), 3) + 
							RIGHT(CAST(YEAR(DateFrom) AS VARCHAR(4)), 2) + ' - ' + 
							LEFT(DATENAME(M, DateTo), 3) + 
							RIGHT(CAST(YEAR(DateTo) AS VARCHAR(4)), 2)

	/* TEMPORARY TABLE TO HOLD INITIAL DATA SET */

		CREATE TABLE #AfterSaleDataset
					
			(
				Manufacturer VARCHAR(10)
				, VIN VARCHAR(30)
				, EventDateSale DATE
				, YearOfSales CHAR(13)
				, SaleEventID INT
				, DealerCode NVARCHAR(10)
				, Model VARCHAR(20)
				, Market VARCHAR(20)
				, [00-12MIS] DATE
				, [13-24MIS] DATE
				, [25-36MIS] DATE
				, [37-48MIS] DATE
				, [Over48MIS] DATE
				, [00-15MIS] DATE
				, [16-30MIS] DATE 
				, [31-45MIS] DATE
				, [46-60MIS] DATE
				, [ServiceEventCount36MIS] TINYINT
				, [ServiceEventCount37-72MIS] TINYINT
				, UNIQUE(VIN)
			);

		

	/* GET THE GERMAN, JAPANESE SALES EVENTS SINCE THE START OF THE EARLIEST SALE EVENT DATE BANDING */
	-- PP: Germany and Japan ONLY as we receive reg date and not event date

		INSERT INTO #AfterSaleDataset
		
			(
				VIN
				, EventDateSale
			)

			SELECT DISTINCT 
				V.VIN
				, MIN(COALESCE(RegistrationDate, EventDate)) AS SalesEventDate
			FROM Vehicle.Vehicles V
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON V.VehicleID = VPRE.VehicleID
			INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
			INNER JOIN Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
			INNER JOIN dbo.DW_JLRCSPDealers DW ON EPR.PartyID = DW.OutletPartyID
			INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VPRE.EventID = VRE.EventID
			LEFT JOIN Vehicle.Registrations R ON VRE.RegistrationID = R.RegistrationID
			--WHERE YEAR(COALESCE(RegistrationDate, EventDate)) > = 2007
			WHERE COALESCE(RegistrationDate, EventDate) > = (SELECT MIN(DateFrom) FROM #EventDateBandings)
			AND EventTypeID = 1
			AND Market IN ( 'germany','japan')
			GROUP BY V.VIN;


	/* GET RECORDS FROM THE OTHER MARKETS */
	-- PP: All markets
	
		INSERT INTO #AftersaleDataset
		
			(
				VIN
				, EventDateSale
			)

			SELECT 
				VIN
				, MIN(EventDate) AS SalesEventDate 
			FROM Vehicle.Vehicles V
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON V.VehicleID = VPRE.VehicleID
			INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
			WHERE NOT EXISTS 
				(
					SELECT 1
					FROM #AftersaleDataset A
					WHERE V.VIN = A.VIN
				)
			--AND YEAR(E.EventDate) > = 2007
			and E.EventDate > = (SELECT MIN(DateFrom) FROM #EventDateBandings)
			AND E.EventTypeID = 1
			GROUP BY VIN;



	/* MR: OK, IF THAT IS THE REQUIREMENT */
	--PP: delete invalid VINs (Dave's request)

		DELETE FROM #AftersaleDataset
		WHERE 
			(
				VIN NOT LIKE 'SAJ%' 
				AND 
				VIN NOT LIKE 'SAL%'
			);


	/* MR: POPULATE THE EVENTID... IMPLICITLY JAPAN AND GERMANY?? */
	-- PP: Japan and Germany only

		UPDATE ASA
			SET SaleEventID = E.EventID
		FROM Event.Events E
		INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
		INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
		INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VPRE.EventID = VRE.EventID
		INNER JOIN Vehicle.Registrations R ON VRE.RegistrationID = R.RegistrationID
		INNER JOIN #AftersaleDataset ASA ON V.VIN = ASA.VIN AND COALESCE(E.EventDate, R.RegistrationDate) = ASA.EventDateSale;


	/* MR: POPULATE THE EVENTID FOR ALL MARKETS. THIS MAY INCLUDE THE GERMAN/JAPANESE DATA THAT HAVE EVENTDATES? 
	THE CONSTRAINT NEEDS TO BE MORE EXPLICIT  */
	-- PP: All markets

		UPDATE ASA
				SET SaleEventID = E.EventID
		FROM Event.Events E
		INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
		INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
		INNER JOIN #AftersaleDataset ASA ON V.VIN = ASA.VIN AND E.EventDate = ASA.EventDateSale
		WHERE ASA.SaleEventID IS NULL;
		

	/* MR: POPULATE DEALER, MARKET AND MODEL COLUMNS */

		UPDATE #AftersaleDataset
			SET DealerCode = DW.OutletCode
			, Market = DW.Market
			, Manufacturer = DW.Manufacturer
		FROM DW_JLRCSPDealers DW
		INNER JOIN Event.EventPartyRoles EPR ON DW.OutletPartyID = EPR.PartyID
		WHERE #AftersaleDataset.SaleEventID = EPR.EventID;


		UPDATE #AftersaleDataset
			SET Model = M.ModelDescription
		FROM Vehicle.Models M
		INNER JOIN Vehicle.Vehicles V ON M.ModelID = V.ModelID
		WHERE #AftersaleDataset.VIN = V.VIN;


	/* MR: POPULATE EVENTDATE ONE WITH EARLIEST EVENT DATE FROM THE LAST 365 DAYS */

		UPDATE #AftersaleDataset
		SET [00-12MIS] = T.EventDate
		FROM 
			(
				SELECT P.VIN, MIN(EventDate) AS EventDate 
				FROM Event.Events E
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
				INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
				INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
				WHERE EventTypeID IN (2)
				AND DATEDIFF(DAY, EventDateSale, E.EventDate) < = 365 AND EventDate > = EventDateSale
				GROUP BY P.VIN
			) T
		WHERE T.VIN = #AftersaleDataset.VIN;

	/* MR: POPULATE EVENTDATE TWO WITH EARLIEST EVENT DATE FROM BETWEEN 366 AND 730 DAYS */

			UPDATE #AftersaleDataset
				SET [13-24MIS] = T.EventDate
			FROM 
				(
					SELECT P.VIN, MIN(EventDate) AS EventDate 
					FROM Event.Events E
					INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
					INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
					INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
					WHERE EventTypeID IN (2)
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 366
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 730
					AND EventDate > = EventDateSale
					GROUP BY P.VIN
				) T
			WHERE T.VIN = #AftersaleDataset.VIN;

	/* MR: POPULATE EVENTDATE THREE WITH EARLIEST EVENT DATE FROM BETWEEN 731 AND 1095 DAYS */

			UPDATE #AftersaleDataset
				SET [25-36MIS] = T.EventDate
			FROM 
				(
					SELECT P.VIN, MIN(EventDate) AS EventDate 
					FROM Event.Events E
					INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
					INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
					INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
					WHERE EventTypeID IN (2)
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 731
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 1095
					AND EventDate > = EventDateSale
					GROUP BY P.VIN
				) T
			WHERE T.VIN = #AftersaleDataset.VIN;

	/* MR: POPULATE EVENTDATE FOUR WITH EARLIEST EVENT DATE FROM BETWEEN 1096 AND 1460 DAYS */

			UPDATE #AftersaleDataset
				SET [37-48MIS] = T.EventDate
			FROM 
				(
					SELECT P.VIN, MIN(EventDate) AS EventDate 
					FROM Event.Events E
					INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
					INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
					INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
					WHERE EventTypeID IN (2)
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 1096
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 1460
					AND EventDate > = EventDateSale
					GROUP BY P.VIN
				) T
			WHERE T.VIN = #AftersaleDataset.VIN;

	/* MR: POPULATE EVENTDATE FIVE WITH EARLIEST EVENT DATE > 1461 */
	

		UPDATE #AftersaleDataset
				SET [Over48MIS] = T.EventDate
				FROM 
					(
						SELECT P.VIN, MIN(EventDate) AS EventDate 
						FROM Event.Events E
						INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
						INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
						INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
						WHERE EventTypeID IN (2)
						AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 1461 
						AND EventDate > = EventDateSale
						GROUP BY P.VIN
					) T
				WHERE T.VIN = #AftersaleDataset.VIN;


		/* MR: POPULATE NEW EVENTDATE ONE WITH EARLIEST EVENT DATE < 456 */

			UPDATE #AftersaleDataset
				SET [00-15MIS] = T.EventDate
			FROM 
				(
					SELECT P.VIN, MIN(EventDate) AS EventDate 
					FROM Event.Events E
					INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
					INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
					INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
					WHERE EventTypeID IN (2)
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) < = 456 
					AND EventDate > = EventDateSale
					GROUP BY P.VIN
				) T
			WHERE T.VIN = #AftersaleDataset.VIN;

		/* MR: POPULATE NEW EVENTDATE TWO WITH EARLIEST EVENT DATE BETWEEN 457 AND 912 */

			UPDATE #AftersaleDataset
				SET [16-30MIS] = T.EventDate
			FROM 
				(
					SELECT P.VIN, MIN(EventDate) AS EventDate 
					FROM Event.Events E
					INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
					INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
					INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
					WHERE EventTypeID IN (2)
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 457
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 912
					AND EventDate > = EventDateSale
					GROUP BY P.VIN
				) T
			WHERE T.VIN = #AftersaleDataset.VIN;


		/* MR: POPULATE NEW EVENTDATE THREE WITH EARLIEST EVENT DATE BETWEEN 913 AND 1368 */

				UPDATE #AftersaleDataset
					SET [31-45MIS] = T.EventDate
				FROM 
				(
					SELECT P.VIN, MIN(EventDate) AS EventDate 
					FROM Event.Events E
					INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
					INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
					INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
					WHERE EventTypeID IN (2)
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 913
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 1368
					AND EventDate > = EventDateSale
					GROUP BY P.VIN
				) T
				WHERE T.VIN = #AftersaleDataset.VIN;

		/* MR: POPULATE NEW EVENTDATE FOUR WITH EARLIEST EVENT DATE BETWEEN 1369 AND 1824 */

			UPDATE #AftersaleDataset
				SET [46-60MIS] = T.EventDate
			FROM 
				(
					SELECT P.VIN, MIN(EventDate) AS EventDate 
					FROM Event.Events E
					INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
					INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
					INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
					WHERE EventTypeID IN (2)
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) >= 1369
					AND DATEDIFF(DAY, EventDateSale, E.EventDate) <= 1824
					AND EventDate > = EventDateSale
					GROUP BY P.VIN
				) T
			WHERE T.VIN = #AftersaleDataset.VIN;

	/* MR: REMOVE SERVICE EVENTS IF THERE IS A WARRANTY CLAIM ON THE SAME DAY */
	
	-- GET ALL WARRANTY SOURCED EVENTS AND SERVICE EVENT DRIVEN EVENT DATES
	
	WITH cteWarrantyEvents
		AS
			(
				SELECT VIN, EventDate
				FROM Meta.VehicleEvents
				WHERE EventTypeID = 3
			)
		, 		
		cteWarranty
		AS
			(
				SELECT VIN, EventDate
				FROM 
					(
						SELECT VIN, [00-12MIS], [13-24MIS], [25-36MIS], [37-48MIS], [Over48MIS], [00-15MIS], [16-30MIS], [31-45MIS], [46-60MIS] 
						FROM #AfterSaleDataset
					) P
				UNPIVOT 
					(
						 EventDate FOR MIS IN ([00-12MIS], [13-24MIS], [25-36MIS], [37-48MIS], [Over48MIS], [00-15MIS], [16-30MIS], [31-45MIS], [46-60MIS])
					) U
			)
	
	-- PUT MATCHES IN TABLE	
		SELECT W.VIN, W.EventDate
		INTO #WarrantyVehiclesToRemove
		FROM cteWarrantyEvents WE
		INNER JOIN cteWarranty W ON WE.VIN = W.VIN
								AND WE.EventDate = W.EventDate;

	-- DELETE SERVICE DATES OF WARRANTY RECORDS
		UPDATE D
			SET [00-15MIS] = NULL 
		FROM #WarrantyVehiclesToRemove R
		INNER JOIN #AfterSaleDataset D ON R.VIN = D.VIN AND R.EventDate = D.[00-15MIS]

		UPDATE D
			SET [16-30MIS] = NULL 
		FROM #WarrantyVehiclesToRemove R
		INNER JOIN #AfterSaleDataset D ON R.VIN = D.VIN AND R.EventDate = D.[16-30MIS]

		UPDATE D
			SET [31-45MIS] = NULL 
		FROM #WarrantyVehiclesToRemove R
		INNER JOIN #AfterSaleDataset D ON R.VIN = D.VIN AND R.EventDate = D.[31-45MIS]

		UPDATE D
			SET [46-60MIS] = NULL 
		FROM #WarrantyVehiclesToRemove R
		INNER JOIN #AfterSaleDataset D ON R.VIN = D.VIN AND R.EventDate = D.[46-60MIS]			
	
	


	/* MR: COUNT THE NUMBER OF DISTINCT EVENTS PER VEHICLE IN THE LAST 3 YEARS */

		UPDATE #AftersaleDataset
			SET ServiceEventCount36MIS = T.EventCount
		FROM 
			(
				SELECT P.VIN, COUNT(DISTINCT E.EventID) AS EventCount 
				FROM Event.Events E
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
				INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
				INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
				WHERE EventTypeID IN (2)
				AND (DATEDIFF(DAY, EventDateSale, E.EventDate) > = 0
				AND DATEDIFF(DAY, EventDateSale, E.EventDate) < = 1095)
				GROUP BY P.VIN
			) T
		WHERE T.VIN = #AftersaleDataset.VIN;


	/* MR: COUNT THE NUMBER OF DISTINCT EVENTS PER VEHICLE IN THE LAST 3 TO 6 YEARS */

		UPDATE #AftersaleDataset
			SET [ServiceEventCount37-72MIS] = T.EventCount
		FROM 
			(
				SELECT P.VIN, COUNT(DISTINCT E.EventID) AS EventCount 
				FROM Event.Events E
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
				INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
				INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
				WHERE EventTypeID IN (2)
				AND (DATEDIFF(DAY, EventDateSale, E.EventDate) > = 1096
				AND DATEDIFF(DAY, EventDateSale, E.EventDate) < = 2190)
				GROUP BY P.VIN
			) T
		WHERE T.VIN = #AftersaleDataset.VIN;


	/* CREATE A TABLE TO HOLD THE AGGREGATIONS */

		CREATE TABLE #ServiceRetention
		
			(
				Manufacturer varchar(10)
				, Market varchar(30)
				, YearOfSales varchar(20)
				, NumberOfSales int
				, [00-15MIS] int
				, [16-30MIS] int
				, [31-45MIS] int
				, [46-60MIS] int
				, [+2Events36MIS] int
				, [+2Events37-72MIS] int
			);

	
	/* POPULATE YEAR OF SALES BASED ON EVENTDATERANGE */

		UPDATE ASA
			SET YearOfSales = EDB.YearOfSales
		FROM #AftersaleDataset ASA
		INNER JOIN #EventDateBandings EDB ON ASA.EventDateSale >= EDB.DateFrom AND ASA.EventDateSale <= EDB.DateTo;

	
	/* LETS UNPIVOT THE DATA SO WE HAVE THE DATA WE WANT TO PIVOT ON THE ROW */

		WITH cteServiceRetention (Manufacturer, Market, YearOfSales, MIS, Banding)

		AS
			(
				SELECT Manufacturer, Market, YearOfSales, MIS, Banding
				FROM
				(
					SELECT 
						Manufacturer
						, Market
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
					FROM #AftersaleDataset
				) T
				UNPIVOT 
				(
						-- VALUE FOR COLUMNNAMES IN (LIST OF COLUMN NAMES)
						Banding FOR MIS IN ([00-15MIS], [16-30MIS], [31-45MIS], [46-60MIS])
				) P
			)
			
			INSERT INTO #ServiceRetention
				
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


	/* ADD COUNT OF SALES RECORDS BY MARKET MANUFACTURER */

		UPDATE SR
			SET NumberOfSales = S.NumberOfSales
		FROM #ServiceRetention SR
		INNER JOIN
			(
				SELECT 
					Manufacturer
					, Market
					, YearOfSales
					, COUNT(*) NumberOfSales
				FROM #AftersaleDataset
				GROUP BY 
					Manufacturer
					, Market
					, YearOfSales
			) S
		ON SR.Manufacturer = S.Manufacturer
		AND SR.Market = S.Market
		AND SR.YearOfSales = S.YearOfSales;
		
	
	/* ADD COUNT OF VEHICLES WITH +2 SERVICE EVENTS WITHIN 36MIS */	
	
			UPDATE SR
				SET [+2Events36MIS] = s.[+2Events36MIS]
			FROM #ServiceRetention SR
			INNER JOIN
				(
					SELECT 
						Manufacturer
						, Market
						, YearOfSales
						, COUNT(*) AS [+2Events36MIS]
					FROM #AftersaleDataset
					WHERE ServiceEventCount36MIS >= 2
					GROUP BY 
						Manufacturer
						, Market
						, YearOfSales
				) S
			ON SR.Manufacturer = S.Manufacturer
			AND SR.Market = S.Market
			AND SR.YearOfSales = S.YearOfSales;

	/* ADD COUNT OF VEHICLES WITH +2 SERVICE EVENTS BETWEEN 37MIS AND 72MIS */	
	
			UPDATE SR
				SET [+2Events37-72MIS] = s.[+2Events37-72MIS]
			FROM #ServiceRetention SR
			INNER JOIN
				(
					SELECT 
						Manufacturer
						, Market
						, YearOfSales
						, COUNT(*) AS [+2Events37-72MIS]
					FROM #AftersaleDataset
					WHERE [ServiceEventCount37-72MIS] >= 2
					GROUP BY 
						Manufacturer
						, Market
						, YearOfSales
				) S
			ON SR.Manufacturer = S.Manufacturer
			AND SR.Market = S.Market
			AND SR.YearOfSales = S.YearOfSales;

	/* 
		THE DATA HAS GAPS IN IT (E.G. CHINA HAS NO 2007 DATA) THEREFORE WILL HAVE TO CREATE A TABLE TO HOLD THE DATA 
		FOR OUTPUT AND THEN PUSH RELEVANT DATA INTO IT WHERE WE HAVE IT. 
		ITS A HORRID HARD CODED HACK BUT THE DATA SIMPLY DOESN'T SUPPORT WHAT WAS CREATED MANUALLY BY HAND 
	*/

		CREATE TABLE #JLRMISREPORT 
		
			(
				ID int identity(1, 1)
				, Manufacturer varchar(10)
				, Market varchar(30)
				, YearOfSales varchar(20)
				, NumberOfSales int
				, [00-15MIS] int
				, [16-30MIS] int
				, [31-45MIS] int
				, [46-60MIS] int
				, [00-15MIS %] varchar(4)
				, [16-30MIS %] varchar(4)
				, [31-45MIS %] varchar(4)
				, [46-60MIS %] varchar(4)
				, ManufacturerII varchar(10)
				, MarketII varchar(30)
				, YearOfSalesII varchar(20)
				, NumberOfSalesII int
				, [00-15MISII] int
				, [16-30MISII] int
				, [31-45MISII] int
				, [46-60MISII] int
				, [00-15MIS %II] varchar(4)
				, [16-30MIS %II] varchar(4)
				, [31-45MIS %II] varchar(4)
				, [46-60MIS %II] varchar(4)
				, MarketOrder TINYINT
			);
		
	
	
	/* PUT IN THE SEEDING ROWS THE YEAROFSALES IS NOW GOING TO BE DYNAMIC.... BUGGER */

	INSERT INTO #JLRMISReport 
		(
			Manufacturer, Market, YearOfSales, NumberOfSales, [00-15MIS], [16-30MIS], [31-45MIS], [46-60MIS], [00-15MIS %], [16-30MIS %]
			, [31-45MIS %], [46-60MIS %], ManufacturerII, MarketII, YearOfSalesII, NumberOfSalesII, [00-15MISII], [16-30MISII]
			, [31-45MISII], [46-60MISII], [00-15MIS %II], [16-30MIS %II], [31-45MIS %II], [46-60MIS %II], MarketOrder
		)

		SELECT DISTINCT 
			A.Manufacturer 
			, A.Market 
			, B.YearOfSales 
			, 0 AS NumberOfSales 
			, 0 AS [00-15MIS] 
			, 0 AS [16-30MIS] 
			, 0 AS [31-45MIS] 
			, 0 AS [46-60MIS] 
			, '0%' AS [00-15MIS %] 
			, '0%' AS [16-30MIS %] 
			, '0%' AS [31-45MIS %] 
			, '0%' AS [46-60MIS %] 
			, 'Jaguar' AS ManufacturerII 
			, A.Market AS MarketII 
			, B.YearOfSales AS YearOfSalesII
			, 0 AS NumberOfSalesII 
			, 0 AS [00-15MISII] 
			, 0 AS [16-30MISII] 
			, 0 AS [31-45MISII] 
			, 0 AS [46-60MISII] 
			, '0%' AS [00-15MIS %II] 
			, '0%' AS [16-30MIS %II] 
			, '0%' AS [31-45MIS %II] 
			, '0%' AS [46-60MIS %II]
			, CASE Market
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
			END	MarketOrder
		FROM #AftersaleDataset A
		CROSS join #EventDateBandings B
		WHERE A.market in ('UK', 'France', 'Germany', 
		'Spain', 'China', 'Russian Federation', 'Japan', 'Netherlands', 'Portugal', 'Switzerland', 'Brazil'
		,'Australia', 'Korea', 'South Africa')
		AND A.Manufacturer = 'land rover'
		order by MarketOrder



	
	CREATE TABLE #JLREventsReport
	
		(
			ID int identity(1, 1)
			, Manufacturer varchar(10)
			, Market varchar(30)
			, YearOfSales varchar(20)
			, NumberOfSales int
			, [+2Events36MIS] int
			, [+2Events36MIS %] varchar(4)
			, [+2Events37-72MIS] int
			, [+2Events37-72MIS %] varchar(4)
			, ManufacturerII varchar(10)
			, MarketII varchar(30)
			, YearOfSalesII varchar(20)
			, NumberOfSalesII int
			, [+2Events36MISII] int
			, [+2Events36MIS %II] varchar(4)
			, [+2Events37-72MISII] int
			, [+2Events37-72MIS %II] varchar(4)
			, MarketOrder tinyint
		);

	INSERT INTO #JLREventsReport
		(Manufacturer, Market, YearOfSales, NumberOfSales, [+2Events36MIS], [+2Events36MIS %], [+2Events37-72MIS], [+2Events37-72MIS %], ManufacturerII, MarketII
			, YearOfSalesII, NumberOfSalesII, [+2Events36MISII], [+2Events36MIS %II], [+2Events37-72MISII], [+2Events37-72MIS %II], MarketOrder)

		SELECT DISTINCT
			A.Manufacturer 
			, A.Market 
			, B.YearOfSales 
			, 0 AS NumberOfSales 	
			, 0 AS [+2Events36MIS]
			, '0%' AS [+2Events36MIS %]
			, 0 AS [+2Events37-72MIS]
			, '0%' AS [+2Events37-72MIS %]
			, 'Jaguar' AS ManufacturerII 
			, A.Market AS MarketII
			, B.YearOfSales AS YearOfSalesII 
			, 0 AS NumberOfSales 	
			, 0 AS [+2Events36MIS]
			, '0%' AS [+2Events36MIS %]
			, 0 AS [+2Events37-72MIS]
			, '0%' AS [+2Events37-72MIS %]
			, CASE A.Market
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
			END	MarketOrder
		FROM #AftersaleDataset A
		CROSS join #EventDateBandings B
		WHERE A.Market IN ('UK', 'France', 'Germany', 
		'Spain', 'China', 'Russian Federation', 'Japan', 'Netherlands', 'Portugal', 'Switzerland', 'Brazil'
		,'Australia', 'Korea', 'South Africa')
		AND Manufacturer = 'land rover'
		ORDER BY MarketOrder	

			
	/* RETURN JLR SERVICE RETENTION BY MARKET / MIS */
		
		-- ADD LAND ROVER AGGREGATIONS
--select * from #JLREventsReport
--select * from #ServiceRetention

		UPDATE R
			SET 
				NumberOfSales = SR.NumberOfSales
				, [00-15MIS] = SR.[00-15MIS]
				, [16-30MIS] = SR.[16-30MIS]
				, [31-45MIS] = SR.[31-45MIS]
				, [46-60MIS] = SR.[46-60MIS]
				, [00-15MIS %] = CAST(CAST(ROUND((CAST(SR.[00-15MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
				, [16-30MIS %] = CAST(CAST(ROUND((CAST(SR.[16-30MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
				, [31-45MIS %] = CAST(CAST(ROUND((CAST(SR.[31-45MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
				, [46-60MIS %] = CAST(CAST(ROUND((CAST(SR.[46-60MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
				FROM #ServiceRetention SR
				INNER JOIN #JLRMISReport R ON SR.Manufacturer = R.Manufacturer
											AND SR.Market = R.Market
											AND SR.YearOfSales = R.YearOfSales		
				WHERE SR.Market IN ('Brazil', 'China', 'France', 'Germany', 'Japan', 'Netherlands', 'Portugal', 'Russian Federation', 'Spain', 'Switzerland', 'UK', 'Australia', 'Korea', 'South Africa')
				AND SR.Manufacturer = 'Land Rover'

--select 
	--SR.NumberOfSales
	--, SR.[00-15MIS]
	--, SR.[16-30MIS]
	--, SR.[31-45MIS]
	--, SR.[46-60MIS]
	--, CAST(CAST(ROUND((CAST(SR.[00-15MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
	--, CAST(CAST(ROUND((CAST(SR.[16-30MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
	--, CAST(CAST(ROUND((CAST(SR.[31-45MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
	--, CAST(CAST(ROUND((CAST(SR.[46-60MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'				
--FROM #ServiceRetention SR
		--INNER JOIN #JLRMISReport R ON SR.Manufacturer = R.Manufacturer
									--AND SR.Market = R.Market
									--AND SR.YearOfSales = R.YearOfSales		
		--WHERE SR.Market IN ('Brazil', 'China', 'France', 'Germany', 'Japan', 'Netherlands', 'Portugal', 'Russian Federation', 'Spain', 'Switzerland', 'UK', 'Australia', 'Korea', 'South Africa')
		--AND SR.Manufacturer = 'Land Rover'

		-- ADD JAGUAR AGGREGATIONS
		UPDATE R
			SET 
				NumberOfSalesII = SR.NumberOfSales
				, [00-15MISII] = SR.[00-15MIS]
				, [16-30MISII] = SR.[16-30MIS]
				, [31-45MISII] = SR.[31-45MIS]
				, [46-60MISII] = SR.[46-60MIS]
				, [00-15MIS %II] = CAST(CAST(ROUND((CAST(SR.[00-15MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
				, [16-30MIS %II] = CAST(CAST(ROUND((CAST(SR.[16-30MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
				, [31-45MIS %II] = CAST(CAST(ROUND((CAST(SR.[31-45MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
				, [46-60MIS %II] = CAST(CAST(ROUND((CAST(SR.[46-60MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
		FROM #ServiceRetention SR
		INNER JOIN #JLRMISReport R ON SR.Manufacturer = R.ManufacturerII
								AND SR.Market = R.MarketII
								AND SR.YearOfSales = R.YearOfSalesII		
		WHERE SR.Market IN ('Brazil', 'China', 'France', 'Germany', 'Japan', 'Netherlands', 'Portugal', 'Russian Federation', 'Spain', 'Switzerland', 'UK', 'Australia', 'Korea', 'South Africa')
		AND sr.MANUFACTURER = 'Jaguar'

		--- RETURN DATA SET
		SELECT 
			[Manufacturer]
			, [Market]
			, [YearOfSales]
			, [NumberOfSales]
			, [00-15MIS]
			, [16-30MIS]
			, [31-45MIS]
			, [46-60MIS]
			, [00-15MIS %]
			, [16-30MIS %]
			, [31-45MIS %]
			, [46-60MIS %]
			, [ManufacturerII] AS [Manufacturer]
			, [MarketII] AS [Market]
			, [YearOfSalesII] AS [YearOfSales]
			, [NumberOfSalesII] AS [NumberOfSales]
			, [00-15MISII] AS [00-15MIS]
			, [16-30MISII] AS [16-30MIS]
			, [31-45MISII] AS [31-45MIS]
			, [46-60MISII] AS [46-60MIS]
			, [00-15MIS %II] AS [00-15MIS %]
			, [16-30MIS %II] AS [16-30MIS %]
			, [31-45MIS %II] AS [31-45MIS %]
			, [46-60MIS %II] AS [46-60MIS %]
		FROM #JLRMISReport
		ORDER BY MarketOrder, YearOfSalesII

	/* RETURN JLR SERVICE RETENTION 2 + SERVICE EVENTS WITHIN 36 MIS */
	
		UPDATE R
			SET NumberOfSales = SR.NumberOfSales
			, [+2Events36MIS] = SR.[+2Events36MIS]
			, [+2Events36MIS %] = CAST(CAST(ROUND((CAST(SR.[+2EVENTS36MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
			, [+2Events37-72MIS] = SR.[+2Events37-72MIS]
			, [+2Events37-72MIS %] = CAST(CAST(ROUND((CAST(SR.[+2EVENTS37-72MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
		FROM #ServiceRetention sr
		INNER JOIN #JLREventsReport R ON SR.Manufacturer = R.Manufacturer
								AND SR.Market = R.Market
								AND SR.YearOfSales = R.YearOfSales		
		WHERE SR.Market IN ('Brazil', 'China', 'France', 'Germany', 'Japan', 'Netherlands', 'Portugal', 'Russian Federation', 'Spain', 'Switzerland', 'UK', 'Australia', 'Korea', 'South Africa')
		AND SR.Manufacturer = 'Land Rover'
		

		UPDATE R
			SET NumberOfSalesII = SR.NumberOfSales
			, [+2Events36MISII] = SR.[+2Events36MIS]
			, [+2Events36MIS %II] = CAST(CAST(ROUND((CAST(SR.[+2EVENTS36MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
			, [+2Events37-72MISII] = SR.[+2Events37-72MIS]
			, [+2Events37-72MIS %II] = CAST(CAST(ROUND((CAST(SR.[+2EVENTS37-72MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
		FROM #ServiceRetention SR
		INNER JOIN #JLREventsReport R ON SR.Manufacturer = R.ManufacturerII
								AND SR.Market = R.MarketII
								AND SR.YearOfSales = R.YearOfSalesII
		WHERE SR.Market IN ('Brazil', 'China', 'France', 'Germany', 'Japan', 'Netherlands', 'Portugal', 'Russian Federation', 'Spain', 'Switzerland', 'UK', 'Australia', 'Korea', 'South Africa')
		AND SR.Manufacturer = 'Jaguar'

		SELECT 
			[Manufacturer]
			, [Market]
			, [YearOfSales]
			, [NumberOfSales]
			, ISNULL([+2Events36MIS], 0) AS [+2Events36MIS]
			, ISNULL([+2Events36MIS %], '0%') AS [+2Events36MIS %]
			, ISNULL([+2Events37-72MIS], 0) AS [+2Events37-72MIS]
			, ISNULL([+2Events37-72MIS %], '0%') AS [+2Events37-72MIS %]
			, [ManufacturerII] AS Manufacturer
			, [MarketII] AS Market
			, [YearOfSalesII] AS YearOfSales
			, [NumberOfSalesII] AS NumberOfSales
			, ISNULL([+2Events36MISII], 0) AS [+2Events36MIS]
			, ISNULL([+2Events36MIS %II], '0%') AS [+2Events36MIS %]
			, ISNULL([+2Events37-72MISII], 0) AS [+2Events37-72MIS]
			, ISNULL([+2Events37-72MIS %II], '0%') AS [+2Events37-72MIS %]
 		FROM #JLREventsReport
 		ORDER BY MarketOrder, YearOfSalesII