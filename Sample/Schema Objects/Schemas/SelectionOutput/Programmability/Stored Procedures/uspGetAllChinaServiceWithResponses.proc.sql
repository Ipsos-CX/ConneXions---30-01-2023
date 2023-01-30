CREATE PROCEDURE SelectionOutput.uspGetAllChinaServiceWithResponses

AS /*

Description:  Gets all China Service with Responses for output to DP. 
------------  Called by: Selection Output.dtsx (Output All Sales - Data Flow Task)	

Version		Created			Author			History		
-------		-------			------			-------			
1.0			27-07-2015		Chris Ross		Original version 
1.1			22-03-2017		Chris Ledger	Bug 13657 - Output Surname, Fullname, DearName & CoName as blank
1.2			21-06-2017		Ben King		BUG 14020 - Ouput Factory of Build, SVODealer and SVOVehicle
1.3			19-07-2017		Eddie Thomas	BUG 14099 - China - New data map July 2017
1.4			10-04-2019		Chris Ross		BUG 15340 - Add in two new columns: Q24 and Q9b
1.5			18-11-2019		Chris Ledger	BUG 16750 - Add in 9 new columns: Q9anew1, Q9anew2, Q9anew3, Q9anew4, Q9anew5, Q9anew6, Q9anew7, Q9anew30, Q9anew9Verbatim
*/

    DECLARE @NOW DATETIME
    SET @NOW = GETDATE()

    SELECT  O.Password ,
            O.ID ,
            O.FullModel ,
            O.Model ,
            O.sType ,
            REPLACE(O.CarReg, CHAR(9), '') AS CarReg,
            REPLACE(O.Title , CHAR(9), '') AS Title,
            REPLACE(O.Initial , CHAR(9), '') AS Initial,
            N'' AS Surname,		-- V1.1
            N'' AS Fullname,	-- V1.1
            N'' AS DearName,	-- V1.1
            N'' AS CoName,		-- V1.1
            REPLACE(O.Add1 , CHAR(9), '') AS Add1,
            REPLACE(O.Add2 , CHAR(9), '') AS Add2,
            REPLACE(O.Add3 , CHAR(9), '') AS Add3,
            REPLACE(O.Add4 , CHAR(9), '') AS Add4,
            REPLACE(O.Add5 , CHAR(9), '') AS Add5,
            REPLACE(O.Add6 , CHAR(9), '') AS Add6,
            REPLACE(O.Add7 , CHAR(9), '') AS Add7,
            REPLACE(O.Add8 , CHAR(9), '') AS Add8,
            REPLACE(O.Add9 , CHAR(9), '') AS Add9,
            O.CTRY ,
            REPLACE(O.EmailAddress , CHAR(9), '') AS EmailAddress,
            O.Dealer ,
            O.sno ,
            O.ccode ,
            O.modelcode ,
            O.lang ,
            O.manuf ,
            O.gender ,
            O.qver ,
            O.blank ,
            O.etype ,
            O.reminder ,
            O.week ,
            O.test ,
            O.SampleFlag ,
            O.SalesServiceFile ,
            O.ITYPE ,
            O.Expired ,
            REPLACE(O.VIN , CHAR(9), '') AS VIN,
            REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate ,
            O.DealerCode ,
            REPLACE(O.Telephone , CHAR(9), '') AS Telephone,
            REPLACE(O.WorkTel , CHAR(9), '') AS WorkTel,
            REPLACE(O.MobilePhone , CHAR(9), '') AS MobilePhone,
            O.ManufacturerDealerCode ,
            O.ModelYear ,
            REPLACE(O.CustomerIdentifier , CHAR(9), '') AS CustomerIdentifier,
            O.OwnershipCycle ,
            O.OutletPartyID ,
            O.PartyID ,
            O.GDDDealerCode ,
            O.ReportingDealerPartyID ,
            O.VariantID ,
            O.ModelVariant ,
            CONVERT(NVARCHAR(10), @NOW, 121) AS SelectionDate ,
			CONVERT(NVARCHAR(100),
            CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
            + CASE WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
                   ELSE O.ITYPE
              END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
            + CASE WHEN O.manuf = 2 THEN 'J'
                   WHEN O.manuf = 3 THEN 'L'
                   ELSE 'UknownManufacturer'
              END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
			CSA.ResponseID, 
			CSA.InterviewerNumber,
			CSA.ResponseDate, 
			CSA.Q1Response, 
			CSA.Q1Verbatim, 
			CSA.Q2Response,  
			CSA.Q3Response, 
			CSA.Q4Response, 
			CSA.Q5Response, 
			CSA.Q5aResponse, 
			CSA.Q6Response, 
			CSA.Q7Response,  
			CSA.Q8Response, 
			CSA.Q9Response,  
			CSA.Q9aResponse, 
			CSA.Q9aOptionResponse, 
			CSA.Q9aOption9verbatim, 
			CSA.Q10Response, 
			CSA.Q10aOptionResponse, 
			CSA.Q10Option9Verbatim, 
			CSA.Q11Response,
			CSA.Q12Response, 
			CSA.Q13Response, 
			CSA.Q14Response,  
			CSA.Q14aResponse,  
			CSA.Q14bResponse,  
			CSA.Q15Response, 
			CSA.Q16Response,
			CSA.Q17Response,
			CSA.AnonymousToRetailer, 
			CSA.AnonymousToManufacturer,
			CSA.Q3Verbatim,
			CSA.Q5Verbatim,	
			CSA.Q6Verbatim,
			CSA.Q7Verbatim,	
			CSA.Q8Verbatim,
			CSA.Q9Verbatim,
			CSA.Q12Verbatim,
			CSA.Q13Verbatim,
			CSA.Q15Verbatim,
			CSA.Q17Verbatim,
			CSA.Q2Verbatim,							-- V1.3
			CSA.Q5h,								-- V1.3
			CSA.Q12 AS [Q12 Response],				-- V1.3
			CSA.Q14c AS Q14cResponse,				-- V1.3
			CSA.Q14cVerbatim,						-- V1.3
			CSA.Q19 AS Q19Response,					-- V1.3
			CSA.Q19Verbatim,						-- V1.3
			CSA.Q20 AS Q20Response,					-- V1.3
			CSA.Q20aVerbatim,						-- V1.3
			CSA.Q21 AS Q21Response,					-- V1.3
			CSA.Q21Verbatim,						-- V1.3
			CSA.Q22 AS Q22Response,					-- V1.3																																																																																																																																																																																																																																																																																																									
			CSA.Q22Verbatim,						-- V1.3
			CSA.QCN1 AS QCN1Response,				-- V1.3
			CSA.QCN2 AS QCN2Response,				-- V1.3
			O.FOBCode, -- V1.3
			ISNULL(O.SVOvehicle,0) As SVOvehicle,	-- V1.2
			ISNULL(O.SVODealer,0) AS SVODealer,	    -- V1.2
			CSA.Q24 AS Q24Response,					-- V1.4
			CSA.Q9b AS Q9bResponse,					-- V1.4
			CSA.Q9anew1 AS Q9anew1Response,			-- V1.5 
			CSA.Q9anew2 AS Q9anew2Response,			-- V1.5 
			CSA.Q9anew3 AS Q9anew3Response,			-- V1.5
			CSA.Q9anew4 AS Q9anew4Response,			-- V1.5
			CSA.Q9anew5 AS Q9anew5Response,			-- V1.5
			CSA.Q9anew6 AS Q9anew6Response,			-- V1.5 
			CSA.Q9anew7 AS Q9anew7Response,			-- V1.5
			CSA.Q9anew30 AS Q9anew30Response,		-- V1.5
			CSA.Q9anew9Verbatim AS Q9anew9Verbatim	-- V1.5
			
    FROM    SelectionOutput.OnlineOutput AS O
    INNER JOIN Sample_ETL.China.Service_WithResponses CSA ON O.ID = CSA.CaseID 		
	