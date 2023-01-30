CREATE PROCEDURE [SelectionOutput].[uspGetAllChinaRoadsideWithResponses]

AS

	DECLARE @NOW	DATETIME,	
			@dtCATI	DATETIME	--v1.2
    
	SET		@NOW = GETDATE()
	SET		@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4) --v1.2


	SELECT		O.Password, 
				O.ID, 
				O.FullModel, 
				O.Model, 
				O.sType, 
				O.CarReg, 
				REPLACE(O.Title,  CHAR(9), '') AS Title,
				REPLACE(O.Initial,   CHAR(9), '') AS Initial,
				N'' AS Surname,		-- V1.1
				N'' AS Fullname,		-- V1.1
				N'' AS DearName,		-- V1.1
				N'' AS CoName,		-- V1.1
				REPLACE(O.Add1,   CHAR(9), '') AS Add1,
				REPLACE(O.Add2,   CHAR(9), '') AS Add2,
				REPLACE(O.Add3,   CHAR(9), '') AS Add3,
				REPLACE(O.Add4,   CHAR(9), '') AS Add4,
				REPLACE(O.Add5,   CHAR(9), '') AS Add5,
				REPLACE(O.Add6,   CHAR(9), '') AS Add6,
				REPLACE(O.Add7,   CHAR(9), '') AS Add7,
				REPLACE(O.Add8,   CHAR(9), '') AS Add8,
				REPLACE(O.Add9,   CHAR(9), '') AS Add9,
				O.CTRY, 
				REPLACE(O.EmailAddress,   CHAR(9), '') AS EmailAddress,
				RWR.DealerCode AS Dealer, 
				O.sno, 
				O.ccode, 
				O.modelcode, 
				O.lang, 
				O.manuf, 
				O.gender, 
				O.qver, 
				O.blank, 
				O.etype, 
				O.reminder, 
				O.week, 
				O.test, 
				O.SampleFlag, 
				O.SalesServiceFile, 
				O.ITYPE, 
				O.Expired,
				O.PartyID,
				RWR.BreakdownDate, 
				RWR.BreakdownCountry AS BreakdownCountry, 
				RWR.CountryID AS BreakdownCountryID, 
				REPLACE(RWR.BreakdownCaseId,   CHAR(9), '') AS BreakdownCaseId,
				REPLACE(RWR.CarHireStartDate,   CHAR(9), '') AS CarHireStartDate,
				REPLACE(RWR.ReasonForHire,   CHAR(9), '') AS ReasonForHire,
				REPLACE(RWR.CarHireGroupBranch,   CHAR(9), '') AS HireGroupBranch,
				REPLACE(RWR.CarHireTicketNumber,   CHAR(9), '') AS CarHireTicketNumber,
				REPLACE(RWR.CarHireJobNumber,   CHAR(9), '') AS HireJobNumber,
				REPLACE(RWR.RepairingDealerCode,   CHAR(9), '') AS RepairingDealer,
				REPLACE(RWR.DataSource,  CHAR(9), '') AS DataSource,
				REPLACE(RWR.carHireMake,  CHAR(9), '') AS ReplacementVehicleMake,
				REPLACE(RWR.CarHireModel,  CHAR(9), '') AS ReplacementVehicleModel,
				REPLACE(RWR.CarHireStartTime,  CHAR(9), '') AS CarHireStartTime,
				RWR.ConvertedCarHireStartTime,
				REPLACE(RWR.RepairingDealerCountry,  CHAR(9), '') AS RepairingDealerCountry,
				REPLACE(RWR.RoadsideAssistanceProvider,  CHAR(9), '') AS RoadsideAssistanceProvider,
				REPLACE(RWR.BreakdownAttendingResource,  CHAR(9), '') AS BreakdownAttendingResource,
				REPLACE(RWR.CarHireProvider,  CHAR(9), '') AS CarHireProvider,
				REPLACE(O.VIN,  CHAR(9), '') AS VIN,
				REPLACE(RWR.CountryCode,  CHAR(9), '') AS VehicleOriginCountry,
				REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,
				CASE
				         WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121) 
				         ELSE CONVERT(NVARCHAR(10), @NOW, 121)
		 	    END AS SelectionDate,
				CONVERT(NVARCHAR(100),
				CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
					+	CASE WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
							ELSE O.ITYPE
						END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
					+	CASE WHEN O.manuf = 2 THEN 'J'
							WHEN O.manuf = 3 THEN 'L'
						ELSE 'UknownManufacturer'
						END + '_' 
					+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
				REPLACE(O.[Telephone],  CHAR(9), '') AS [Telephone],
				REPLACE(O.[WorkTel],  CHAR(9), '') AS [WorkTel],
				REPLACE(O.[MobilePhone],  CHAR(9), '') AS [MobilePhone],
				O.ModelSummary,
				RWR.ResponseID,
				RWR.InterviewerNumber,
				RWR.ResponseDate,
				RWR.Q1Response,
				RWR.Q1Verbatim,
				RWR.Q2Response,
				RWR.Q2_2,
				RWR.Q2_3Response,
				RWR.Q2_4,
				RWR.Q2_5,
				RWR.Q2_6,
				RWR.Q2_7,
				RWR.Q2_8,
				RWR.Q2_9,
				RWR.Q3Response,
				RWR.Q4Response,
				RWR.Q4_1Response,
				RWR.Q4_2,
				RWR.Q4_3,
				RWR.Q4_4,
				RWR.Q5Response,
				RWR.Q5_1Response,
				RWR.Q5_2,
				RWR.Q6_0,
				RWR.Q61,
				RWR.Q62,
				RWR.Q63,
				RWR.Q64,
				RWR.Q65,
				RWR.Q66,
				RWR.Q67,
				RWR.Q8Response,
				RWR.Q8Verbatim,
				RWR.Q9Response,
				RWR.Q10,
				RWR.Q10Verbatim,
				RWR.Q12Verbatim,
				RWR.Q13Response,
				RWR.Q11Response,
				RWR.AnonymousToRetailer

	FROM		SelectionOutput.OnlineOutput AS O
	INNER JOIN	Sample_ETL.China.Roadside_WithResponses RWR ON O.ID = RWR.CaseID
