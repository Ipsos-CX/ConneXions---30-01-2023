CREATE PROCEDURE dbo.uspGET_ServiceSampleAnalysisData

AS

	/*
		Purpose:	
		
		Version		Date			Developer			Comment
		1.0			??/??/????		Poorvi Prasad		Created initial dataset
		1.1			03/04/2013		Martin Riverol		Renamed intial dataset columns to make them more explicit and added the 
														actual aggregations to match what was produced manually in excel.
	*/


	/* SET LOCAL CONNECTION VARIABLES */
	
		SET XACT_ABORT ON
		SET NOCOUNT ON

	/* TEMPORARY TABLE TO HOLD INITIAL DATA SET */

		CREATE TABLE #AfterSaleDataset
					
			(
				Manufacturer VARCHAR(10)
				, VIN VARCHAR(30)
				, EventDateSale DATE
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
				, [ServiceEventCount48MIS] TINYINT
			);

		

	/* GET THE GERMAN, JAPANESE SALES EVENTS SINCE 2007. TAKE THE FIRST SALE DATE OF 2007 */
	-- PP: Germany and Japan ONLY as we receive reg date and not event date

		INSERT INTO #AfterSaleDataset
		
			(
				VIN
				, EventDateSale
			)

			SELECT DISTINCT 
				V.VIN
				, MIN(COALESCE(RegistrationDate, EventDate)) AS SalesEventDate
			FROM Sample.Vehicle.Vehicles V
			INNER JOIN Sample.Vehicle.VehiclePartyRoleEvents VPRE ON V.VehicleID = VPRE.VehicleID
			INNER JOIN Sample.Event.Events E ON VPRE.EventID = E.EventID
			INNER JOIN Sample.Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
			INNER JOIN Sample.DBO.DW_JLRCSPDealers DW ON EPR.PartyID = DW.OutletPartyID
			INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VPRE.EventID = VRE.EventID
			LEFT JOIN Vehicle.Registrations R ON VRE.RegistrationID = R.RegistrationID
			WHERE YEAR(COALESCE(RegistrationDate, EventDate)) > = 2007
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
			FROM Sample.Vehicle.Vehicles V
			INNER JOIN Sample.Vehicle.VehiclePartyRoleEvents VPRE ON V.VehicleID = VPRE.VehicleID
			INNER JOIN Sample.Event.Events E ON VPRE.EventID = E.EventID
			WHERE NOT EXISTS 
				(
					SELECT 1
					FROM #AftersaleDataset A
					WHERE V.VIN = A.VIN
				)
			AND YEAR(E.EventDate) > = 2007
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
		FROM Sample.Event.Events E
		INNER JOIN Sample.Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
		INNER JOIN Sample.Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
		INNER JOIN Sample.Vehicle.VehicleRegistrationEvents VRE ON VPRE.EventID = VRE.EventID
		INNER JOIN Sample.Vehicle.Registrations R ON VRE.RegistrationID = R.RegistrationID
		INNER JOIN #AftersaleDataset ASA ON V.VIN = ASA.VIN AND COALESCE(E.EventDate, R.RegistrationDate) = ASA.EventDateSale;


	/* MR: POPULATE THE EVENTID FOR ALL MARKETS. THIS MAY INCLUDE THE GERMAN/JAPANESE DATA THAT HAVE EVENTDATES? 
	THE CONSTRAINT NEEDS TO BE MORE EXPLICIT  */
	-- PP: All markets

		UPDATE ASA
				SET SaleEventID = E.EventID
		FROM Sample.Event.Events E
		INNER JOIN Sample.Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
		INNER JOIN Sample.Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
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
		FROM Sample.Vehicle.Models M
		INNER JOIN Sample.Vehicle.Vehicles V ON M.ModelID = V.ModelID
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


	/* MR: COUNT THE NUMBER OF DISTINCT EVENTS PER VEHICLE IN THE LAST 4 YEARS */

		UPDATE #AftersaleDataset
			SET ServiceEventCount48MIS = T.EventCount
		FROM 
			(
				SELECT P.VIN, COUNT(DISTINCT E.EventID) AS EventCount 
				FROM Event.Events E
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
				INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
				INNER JOIN #AftersaleDataset P ON V.VIN = P.VIN
				WHERE EventTypeID IN (2)
				AND (DATEDIFF(DAY, EventDateSale, E.EventDate) > = 0
				AND DATEDIFF(DAY, EventDateSale, E.EventDate) < = 1461)
				GROUP BY P.VIN
			) T
		WHERE T.VIN = #AftersaleDataset.VIN;


	/* CREATE A TABLE TO HOLD THE AGGREGATIONS */

		CREATE TABLE #ServiceRetention
		
			(
				Manufacturer varchar(10)
				, Market varchar(30)
				, YearOfSales int
				, NumberOfSales int
				, [00-15MIS] int
				, [16-30MIS] int
				, [31-45MIS] int
				, [46-60MIS] int
				, [+2Events36MIS] int
			);

	
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
						, YEAR(EventDateSale) YearOfSales
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
					, YEAR(EventDateSale) YearOfSales
					, COUNT(*) NumberOfSales
				FROM #AftersaleDataset
				GROUP BY 
					Manufacturer
					, Market
					, YEAR(EventDateSale)
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
						, YEAR(EventDateSale) YearOfSales
						, COUNT(*) AS [+2Events36MIS]
					FROM #AftersaleDataset
					WHERE serviceeventcount36mis >= 2
					GROUP BY 
						Manufacturer
						, Market
						, YEAR(EventDateSale)
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
				, YearOfSales int
				, NumberOfSales int
				, [00-15MIS] int
				, [16-30MIS] int
				, [31-45MIS] int
				, [46-60MIS] int
				, [00-15MIS %] varchar(3)
				, [16-30MIS %] varchar(3)
				, [31-45MIS %] varchar(3)
				, [46-60MIS %] varchar(3)
				, ManufacturerII varchar(10)
				, MarketII varchar(30)
				, YearOfSalesII int
				, NumberOfSalesII int
				, [00-15MISII] int
				, [16-30MISII] int
				, [31-45MISII] int
				, [46-60MISII] int
				, [00-15MIS %II] varchar(3)
				, [16-30MIS %II] varchar(3)
				, [31-45MIS %II] varchar(3)
				, [46-60MIS %II] varchar(3)
			);
		
	
	
	/* PUT IN THE SEEDING ROWS */
	
		INSERT INTO #JLRMISReport 
			(Manufacturer, Market, YearOfSales, NumberOfSales, [00-15MIS], [16-30MIS], [31-45MIS], [46-60MIS], [00-15MIS %], [16-30MIS %]
			, [31-45MIS %], [46-60MIS %], ManufacturerII, MarketII, YearOfSalesII, NumberOfSalesII, [00-15MISII], [16-30MISII]
			, [31-45MISII], [46-60MISII], [00-15MIS %II], [16-30MIS %II], [31-45MIS %II], [46-60MIS %II])
		VALUES 
		('Land Rover', 'UK', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'UK', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'UK', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'UK', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'UK', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'UK', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'UK', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'UK', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'UK', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'UK', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'UK', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'UK', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'UK', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'UK', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'France', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'France', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'France', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'France', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'France', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'France', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'France', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'France', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'France', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'France', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'France', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'France', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'France', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'France', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),	
		('Land Rover', 'Germany', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Germany', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Germany', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Germany', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Germany', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Germany', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Germany', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Germany', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Germany', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Germany', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Germany', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Germany', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Germany', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Germany', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Spain', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Spain', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Spain', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Spain', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Spain', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Spain', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Spain', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Spain', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Spain', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Spain', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Spain', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Spain', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Spain', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Spain', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),	
		('Land Rover', 'China', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'China', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'China', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'China', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'China', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'China', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'China', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'China', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'China', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'China', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'China', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'China', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'China', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'China', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),	
		('Land Rover', 'Russian Federation', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Russian Federation', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Russian Federation', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Russian Federation', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Russian Federation', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Russian Federation', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Russian Federation', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Russian Federation', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Russian Federation', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Russian Federation', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Russian Federation', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Russian Federation', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Russian Federation', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Russian Federation', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),	
		('Land Rover', 'Japan', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Japan', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Japan', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Japan', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Japan', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Japan', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Japan', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Japan', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Japan', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Japan', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Japan', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Japan', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Japan', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Japan', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),	
		('Land Rover', 'Netherlands', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Netherlands', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Netherlands', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Netherlands', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Netherlands', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Netherlands', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Netherlands', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Netherlands', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Netherlands', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Netherlands', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Netherlands', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Netherlands', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Netherlands', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Netherlands', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),	
		('Land Rover', 'Portugal', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Portugal', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Portugal', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Portugal', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Portugal', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Portugal', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Portugal', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Portugal', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Portugal', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Portugal', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Portugal', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Portugal', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Portugal', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Portugal', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),	
		('Land Rover', 'Switzerland', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Switzerland', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Switzerland', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Switzerland', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Switzerland', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Switzerland', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Switzerland', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Switzerland', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Switzerland', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Switzerland', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Switzerland', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Switzerland', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Switzerland', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Switzerland', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),	
		('Land Rover', 'Brazil', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Brazil', 2007, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Brazil', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Brazil', 2008, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Brazil', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Brazil', 2009, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Brazil', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Brazil', 2010, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Brazil', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Brazil', 2011, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Brazil', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Brazil', 2012, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%'),
		('Land Rover', 'Brazil', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%', 'Jaguar', 'Brazil', 2013, 0, 0, 0, 0, 0, '0%', '0%', '0%', '0%')	
			
	
	
	CREATE TABLE #JLREventsReport
	
		(
			ID int identity(1, 1)
			, Manufacturer varchar(10)
			, Market varchar(30)
			, YearOfSales int
			, NumberOfSales int
			, [+2Events36MIS] int
			, [+2Events36MIS %] varchar(3)
			, ManufacturerII varchar(10)
			, MarketII varchar(30)
			, YearOfSalesII int
			, NumberOfSalesII int
			, [+2Events36MISII] int
			, [+2Events36MIS %II] varchar(3)
		);

	

	INSERT INTO #JLREventsReport
		(Manufacturer, Market, YearOfSales, NumberOfSales, [+2Events36MIS], [+2Events36MIS %], ManufacturerII, MarketII
			, YearOfSalesII, NumberOfSalesII, [+2Events36MISII], [+2Events36MIS %II])
	VALUES 
	('Land Rover', 'UK', 2007, 0, 0, '0%', 'Jaguar', 'UK', 2007, 0, 0, '0%'),		
	('Land Rover', 'UK', 2008, 0, 0, '0%', 'Jaguar', 'UK', 2008, 0, 0, '0%'),		
	('Land Rover', 'UK', 2009, 0, 0, '0%', 'Jaguar', 'UK', 2009, 0, 0, '0%'),		
	('Land Rover', 'UK', 2010, 0, 0, '0%', 'Jaguar', 'UK', 2010, 0, 0, '0%'),		
	('Land Rover', 'UK', 2011, 0, 0, '0%', 'Jaguar', 'UK', 2011, 0, 0, '0%'),	
	('Land Rover', 'UK', 2012, 0, 0, '0%', 'Jaguar', 'UK', 2012, 0, 0, '0%'),		
	('Land Rover', 'UK', 2013, 0, 0, '0%', 'Jaguar', 'UK', 2013, 0, 0, '0%'),			
	('Land Rover', 'France', 2007, 0, 0, '0%', 'Jaguar', 'France', 2007, 0, 0, '0%'),		
	('Land Rover', 'France', 2008, 0, 0, '0%', 'Jaguar', 'France', 2008, 0, 0, '0%'),		
	('Land Rover', 'France', 2009, 0, 0, '0%', 'Jaguar', 'France', 2009, 0, 0, '0%'),		
	('Land Rover', 'France', 2010, 0, 0, '0%', 'Jaguar', 'France', 2010, 0, 0, '0%'),		
	('Land Rover', 'France', 2011, 0, 0, '0%', 'Jaguar', 'France', 2011, 0, 0, '0%'),	
	('Land Rover', 'France', 2012, 0, 0, '0%', 'Jaguar', 'France', 2012, 0, 0, '0%'),		
	('Land Rover', 'France', 2013, 0, 0, '0%', 'Jaguar', 'France', 2013, 0, 0, '0%'),
	('Land Rover', 'Germany', 2007, 0, 0, '0%', 'Jaguar', 'Germany', 2007, 0, 0, '0%'),		
	('Land Rover', 'Germany', 2008, 0, 0, '0%', 'Jaguar', 'Germany', 2008, 0, 0, '0%'),		
	('Land Rover', 'Germany', 2009, 0, 0, '0%', 'Jaguar', 'Germany', 2009, 0, 0, '0%'),		
	('Land Rover', 'Germany', 2010, 0, 0, '0%', 'Jaguar', 'Germany', 2010, 0, 0, '0%'),		
	('Land Rover', 'Germany', 2011, 0, 0, '0%', 'Jaguar', 'Germany', 2011, 0, 0, '0%'),	
	('Land Rover', 'Germany', 2012, 0, 0, '0%', 'Jaguar', 'Germany', 2012, 0, 0, '0%'),		
	('Land Rover', 'Germany', 2013, 0, 0, '0%', 'Jaguar', 'Germany', 2013, 0, 0, '0%'),
	('Land Rover', 'Spain', 2007, 0, 0, '0%', 'Jaguar', 'Spain', 2007, 0, 0, '0%'),		
	('Land Rover', 'Spain', 2008, 0, 0, '0%', 'Jaguar', 'Spain', 2008, 0, 0, '0%'),		
	('Land Rover', 'Spain', 2009, 0, 0, '0%', 'Jaguar', 'Spain', 2009, 0, 0, '0%'),		
	('Land Rover', 'Spain', 2010, 0, 0, '0%', 'Jaguar', 'Spain', 2010, 0, 0, '0%'),		
	('Land Rover', 'Spain', 2011, 0, 0, '0%', 'Jaguar', 'Spain', 2011, 0, 0, '0%'),	
	('Land Rover', 'Spain', 2012, 0, 0, '0%', 'Jaguar', 'Spain', 2012, 0, 0, '0%'),		
	('Land Rover', 'Spain', 2013, 0, 0, '0%', 'Jaguar', 'Spain', 2013, 0, 0, '0%'),
	('Land Rover', 'China', 2007, 0, 0, '0%', 'Jaguar', 'China', 2007, 0, 0, '0%'),		
	('Land Rover', 'China', 2008, 0, 0, '0%', 'Jaguar', 'China', 2008, 0, 0, '0%'),		
	('Land Rover', 'China', 2009, 0, 0, '0%', 'Jaguar', 'China', 2009, 0, 0, '0%'),		
	('Land Rover', 'China', 2010, 0, 0, '0%', 'Jaguar', 'China', 2010, 0, 0, '0%'),		
	('Land Rover', 'China', 2011, 0, 0, '0%', 'Jaguar', 'China', 2011, 0, 0, '0%'),	
	('Land Rover', 'China', 2012, 0, 0, '0%', 'Jaguar', 'China', 2012, 0, 0, '0%'),		
	('Land Rover', 'China', 2013, 0, 0, '0%', 'Jaguar', 'China', 2013, 0, 0, '0%'),
	('Land Rover', 'Russian Federation', 2007, 0, 0, '0%', 'Jaguar', 'Russian Federation', 2007, 0, 0, '0%'),		
	('Land Rover', 'Russian Federation', 2008, 0, 0, '0%', 'Jaguar', 'Russian Federation', 2008, 0, 0, '0%'),		
	('Land Rover', 'Russian Federation', 2009, 0, 0, '0%', 'Jaguar', 'Russian Federation', 2009, 0, 0, '0%'),		
	('Land Rover', 'Russian Federation', 2010, 0, 0, '0%', 'Jaguar', 'Russian Federation', 2010, 0, 0, '0%'),		
	('Land Rover', 'Russian Federation', 2011, 0, 0, '0%', 'Jaguar', 'Russian Federation', 2011, 0, 0, '0%'),	
	('Land Rover', 'Russian Federation', 2012, 0, 0, '0%', 'Jaguar', 'Russian Federation', 2012, 0, 0, '0%'),		
	('Land Rover', 'Russian Federation', 2013, 0, 0, '0%', 'Jaguar', 'Russian Federation', 2013, 0, 0, '0%'),
	('Land Rover', 'Japan', 2007, 0, 0, '0%', 'Jaguar', 'Japan', 2007, 0, 0, '0%'),		
	('Land Rover', 'Japan', 2008, 0, 0, '0%', 'Jaguar', 'Japan', 2008, 0, 0, '0%'),		
	('Land Rover', 'Japan', 2009, 0, 0, '0%', 'Jaguar', 'Japan', 2009, 0, 0, '0%'),		
	('Land Rover', 'Japan', 2010, 0, 0, '0%', 'Jaguar', 'Japan', 2010, 0, 0, '0%'),		
	('Land Rover', 'Japan', 2011, 0, 0, '0%', 'Jaguar', 'Japan', 2011, 0, 0, '0%'),	
	('Land Rover', 'Japan', 2012, 0, 0, '0%', 'Jaguar', 'Japan', 2012, 0, 0, '0%'),		
	('Land Rover', 'Japan', 2013, 0, 0, '0%', 'Jaguar', 'Japan', 2013, 0, 0, '0%'),
	('Land Rover', 'Netherlands', 2007, 0, 0, '0%', 'Jaguar', 'Netherlands', 2007, 0, 0, '0%'),		
	('Land Rover', 'Netherlands', 2008, 0, 0, '0%', 'Jaguar', 'Netherlands', 2008, 0, 0, '0%'),		
	('Land Rover', 'Netherlands', 2009, 0, 0, '0%', 'Jaguar', 'Netherlands', 2009, 0, 0, '0%'),		
	('Land Rover', 'Netherlands', 2010, 0, 0, '0%', 'Jaguar', 'Netherlands', 2010, 0, 0, '0%'),		
	('Land Rover', 'Netherlands', 2011, 0, 0, '0%', 'Jaguar', 'Netherlands', 2011, 0, 0, '0%'),	
	('Land Rover', 'Netherlands', 2012, 0, 0, '0%', 'Jaguar', 'Netherlands', 2012, 0, 0, '0%'),		
	('Land Rover', 'Netherlands', 2013, 0, 0, '0%', 'Jaguar', 'Netherlands', 2013, 0, 0, '0%'),
	('Land Rover', 'Portugal', 2007, 0, 0, '0%', 'Jaguar', 'Portugal', 2007, 0, 0, '0%'),		
	('Land Rover', 'Portugal', 2008, 0, 0, '0%', 'Jaguar', 'Portugal', 2008, 0, 0, '0%'),		
	('Land Rover', 'Portugal', 2009, 0, 0, '0%', 'Jaguar', 'Portugal', 2009, 0, 0, '0%'),		
	('Land Rover', 'Portugal', 2010, 0, 0, '0%', 'Jaguar', 'Portugal', 2010, 0, 0, '0%'),		
	('Land Rover', 'Portugal', 2011, 0, 0, '0%', 'Jaguar', 'Portugal', 2011, 0, 0, '0%'),	
	('Land Rover', 'Portugal', 2012, 0, 0, '0%', 'Jaguar', 'Portugal', 2012, 0, 0, '0%'),		
	('Land Rover', 'Portugal', 2013, 0, 0, '0%', 'Jaguar', 'Portugal', 2013, 0, 0, '0%'),
	('Land Rover', 'Switzerland', 2007, 0, 0, '0%', 'Jaguar', 'Switzerland', 2007, 0, 0, '0%'),		
	('Land Rover', 'Switzerland', 2008, 0, 0, '0%', 'Jaguar', 'Switzerland', 2008, 0, 0, '0%'),		
	('Land Rover', 'Switzerland', 2009, 0, 0, '0%', 'Jaguar', 'Switzerland', 2009, 0, 0, '0%'),		
	('Land Rover', 'Switzerland', 2010, 0, 0, '0%', 'Jaguar', 'Switzerland', 2010, 0, 0, '0%'),		
	('Land Rover', 'Switzerland', 2011, 0, 0, '0%', 'Jaguar', 'Switzerland', 2011, 0, 0, '0%'),	
	('Land Rover', 'Switzerland', 2012, 0, 0, '0%', 'Jaguar', 'Switzerland', 2012, 0, 0, '0%'),		
	('Land Rover', 'Switzerland', 2013, 0, 0, '0%', 'Jaguar', 'Switzerland', 2013, 0, 0, '0%'),
	('Land Rover', 'Brazil', 2007, 0, 0, '0%', 'Jaguar', 'Brazil', 2007, 0, 0, '0%'),		
	('Land Rover', 'Brazil', 2008, 0, 0, '0%', 'Jaguar', 'Brazil', 2008, 0, 0, '0%'),		
	('Land Rover', 'Brazil', 2009, 0, 0, '0%', 'Jaguar', 'Brazil', 2009, 0, 0, '0%'),		
	('Land Rover', 'Brazil', 2010, 0, 0, '0%', 'Jaguar', 'Brazil', 2010, 0, 0, '0%'),		
	('Land Rover', 'Brazil', 2011, 0, 0, '0%', 'Jaguar', 'Brazil', 2011, 0, 0, '0%'),	
	('Land Rover', 'Brazil', 2012, 0, 0, '0%', 'Jaguar', 'Brazil', 2012, 0, 0, '0%'),		
	('Land Rover', 'Brazil', 2013, 0, 0, '0%', 'Jaguar', 'Brazil', 2013, 0, 0, '0%')
	
			
	/* RETURN JLR SERVICE RETENTION BY MARKET / MIS */
		
		-- ADD LAND ROVER AGGREGATIONS
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
		WHERE SR.YearOfSales < 2014
		AND SR.Market IN ('Brazil', 'China', 'France', 'Germany', 'Japan', 'Netherlands', 'Portugal', 'Russian Federation', 'Spain', 'Switzerland', 'UK')
		AND SR.Manufacturer = 'Land Rover'

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
		WHERE SR.YearOfSales < 2014
		AND SR.Market IN ('Brazil', 'China', 'France', 'Germany', 'Japan', 'Netherlands', 'Portugal', 'Russian Federation', 'Spain', 'Switzerland', 'UK')
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

	/* RETURN JLR SERVICE RETENTION 2 + SERVICE EVENTS WITHIN 36 MIS */
	
		UPDATE R
			SET NumberOfSales = SR.NumberOfSales
			, [+2Events36MIS] = SR.[+2Events36MIS]
			, [+2Events36MIS %] = CAST(CAST(ROUND((CAST(SR.[+2EVENTS36MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
		FROM #ServiceRetention sr
		INNER JOIN #JLREventsReport R ON SR.Manufacturer = R.Manufacturer
								AND SR.Market = R.Market
								AND SR.YearOfSales = R.YearOfSales		
		WHERE SR.YearOfSales < 2014
		AND SR.Market IN ('Brazil', 'China', 'France', 'Germany', 'Japan', 'Netherlands', 'Portugal', 'Russian Federation', 'Spain', 'Switzerland', 'UK')
		AND SR.Manufacturer = 'Land Rover'
		


		UPDATE R
			SET NumberOfSalesII = SR.NumberOfSales
			, [+2Events36MISII] = SR.[+2Events36MIS]
			, [+2Events36MIS %II] = CAST(CAST(ROUND((CAST(SR.[+2EVENTS36MIS] AS DECIMAL(7, 2)) / CAST(SR.NumberOfSales AS DECIMAL(7, 2))) * 100, 0) AS INT) AS VARCHAR(5)) + '%'
		FROM #ServiceRetention SR
		INNER JOIN #JLREventsReport R ON SR.Manufacturer = R.ManufacturerII
								AND SR.Market = R.MarketII
								AND SR.YearOfSales = R.YearOfSalesII
		WHERE SR.YearOfSales < 2014
		AND SR.Market IN ('Brazil', 'China', 'France', 'Germany', 'Japan', 'Netherlands', 'Portugal', 'Russian Federation', 'Spain', 'Switzerland', 'UK')
		AND SR.Manufacturer = 'Jaguar'

		SELECT 
			[Manufacturer]
			, [Market]
			, [YearOfSales]
			, [NumberOfSales]
			, [+2Events36MIS]
			, [+2Events36MIS %]
			, [ManufacturerII] AS Manufacturer
			, [MarketII] AS Market
			, [YearOfSalesII] AS YearOfSales
			, [NumberOfSalesII] AS NumberOfSales
			, ISNULL([+2Events36MISII], 0) AS [+2Events36MIS]
			, ISNULL([+2Events36MIS %II], '0%') AS [+2Events36MIS %]
 		FROM #JLREventsReport