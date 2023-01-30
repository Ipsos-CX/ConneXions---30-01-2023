CREATE PROCEDURE SelectionOutput.uspGetAllChinaWithResponses

AS /*

Description:  Gets all China Sales and Service with Responses for output to DP. 
------------  Called by: Selection Output.dtsx (Output All Sales - Data Flow Task)	

Version		Created			Author			History		
-------		-------			------			-------			
1.0			27-07-2015		Chris Ross		Original version 
1.1			30-05-2016		Chris Ledger	Extra verbatims added
1.2			22-03-2017		Chris Ledger	Bug 13657 - Output Surname, Fullname, DearName & CoName as blank
1.3			13-09-2018		Chris Ledger	Bug 14977 - Add Q21Response
1.4			11-10-2018		Chris Ledger	BUG 15053 - Add Q22Response, Q23Response & Q24Response fields
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
            N'' AS Surname,		-- V1.2
            N'' AS Fullname,	-- V1.2
            N'' AS DearName,	-- V1.2
            N'' AS CoName,		-- V1.2
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
			COALESCE(CSA.ResponseID, CSE.ResponseID) AS ResponseID,
			COALESCE(CSA.InterviewerNumber, CSE.InterviewerNumber) AS InterviewerNumber,
			COALESCE(CSA.ResponseDate, CSE.ResponseDate) AS ResponseDate,
			COALESCE(CSA.Q1Response, CSE.Q1Response) AS Q1Response,
			COALESCE(CSA.Q1Verbatim,  CSE.Q1Verbatim) AS  Q1Verbatim, 
			COALESCE(CSA.Q2Response,  CSE.Q2Response) AS  Q2Response, 
			COALESCE(CSA.Q3Response,  CSE.Q3Response) AS  Q3Response, 
			COALESCE(CSA.Q4Response,  CSE.Q4Response) AS  Q4Response, 
			COALESCE(CSA.Q5Response,  CSE.Q5Response) AS  Q5Response, 
			COALESCE(CSA.Q6Response,  CSE.Q6Response) AS  Q6Response, 
			COALESCE(CSA.Q7Response,  CSE.Q7Response) AS  Q7Response, 
			COALESCE(CSA.Q8Response,  CSE.Q8Response) AS  Q8Response, 
			COALESCE(CSA.Q9Response,  CSE.Q9Response) AS  Q9Response, 
			COALESCE(CSA.Q9aResponse,  CSE.Q9aResponse) AS  Q9aResponse, 
			COALESCE(CSA.Q9aOptionResponse,  CSE.Q9aOptionResponse) AS  Q9aOptionResponse, 
			COALESCE(CSA.Q9aOption6verbatim,  CSE.Q9aOption9verbatim) AS  Q9aOption6verbatim, 
			COALESCE(CSA.Q10Response,  CSE.Q10Response) AS  Q10Response, 
			COALESCE(CSA.Q11Response,  CSE.Q11Response) AS  Q11Response, 
			COALESCE(CSA.Q12Response, CSE. Q12Response) AS  Q12Response, 
			COALESCE(CSA.Q13Response, CSE.Q13Response) AS  Q13Response, 
			COALESCE(CSA.Q14Response,  CSE.Q14Response) AS  Q14Response, 
			COALESCE(CSA.Q15Response,  CSE.Q15Response) AS  Q15Response, 
			COALESCE(CSA.Q16Response,  CSE.Q16Response) AS  Q16Response, 
			COALESCE(CSA.Q17Response,  CSE.Q17Response) AS  Q17Response, 
			COALESCE(CSA.Q18Response,  CSE.Q18Response) AS  Q18Response, 
			COALESCE(CSA.AnonymousToRetailer, CSE.AnonymousToRetailer) AS AnonymousToRetailer, 
			COALESCE(CSA.AnonymousToManufacturer, CSE.AnonymousToManufacturer) AS AnonymousToManufacturer,
			COALESCE(CSA.Q3Verbatim,  CSE.Q3Verbatim) AS  Q3Verbatim, 
			CSA.Q4Verbatim AS  Q4Verbatim, 
			COALESCE(CSA.Q5Verbatim,  CSE.Q5Verbatim) AS  Q5Verbatim, 
			CSE.Q6Verbatim AS  Q6Verbatim, 
			COALESCE(CSA.Q7Verbatim,  CSE.Q7Verbatim) AS  Q7Verbatim, 
			CSE.Q8Verbatim AS  Q8Verbatim, 
			CSE.Q9Verbatim AS  Q9Verbatim, 
			CSA.Q9aVerbatim AS  Q9aVerbatim, 
			CSA.Q10Verbatim AS  Q10Verbatim, 
			COALESCE(CSA.Q12Verbatim,  CSE.Q12Verbatim) AS  Q12Verbatim, 
			CSE.Q13Verbatim AS  Q13Verbatim, 
			CSA.Q14aVerbatim AS  Q14aVerbatim, 
			CSE.Q15Verbatim AS  Q15Verbatim, 
			CSA.Q15aVerbatim AS  Q15aVerbatim, 
			CSA.Q16Verbatim AS  Q16Verbatim, 
			COALESCE(CSA.Q17Verbatim,  CSE.Q17Verbatim) AS  Q17Verbatim,
			CSA.Q21Response,													-- V1.3
			CSA.Q22Response,													-- V1.4
			CSA.Q23Response,													-- V1.4
			CSA.Q24Response														-- V1.4
			
    FROM    SelectionOutput.OnlineOutput AS O
    LEFT JOIN [$(ETLDB)].China.Sales_WithResponses CSA ON O.ID = CSA.CaseID 		
	LEFT JOIN [$(ETLDB)].China.Service_WithResponses CSE ON O.ID = CSE.CaseID 	
	WHERE COALESCE(CSA.CaseID, CSE.CaseID) IS NOT NULL 