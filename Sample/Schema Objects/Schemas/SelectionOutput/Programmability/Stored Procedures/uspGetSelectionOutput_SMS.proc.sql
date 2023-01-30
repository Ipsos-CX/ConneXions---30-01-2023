
CREATE PROCEDURE SelectionOutput.uspGetSelectionOutput_SMS
AS

/*
Version	Created			Author			Purpose							Called by
1.0		05-Feb-2015		P.Doyle			Gets SMS selections				Selection Output.dtsx (SMS - Data Flow Task)	
1.1		08-Nov-2017		E. Thomas		Filter out re-output records	'
1.2		11-Aug-2018		E. Thomas		BUG 14797 - Portugal Roadside - Contact Methodology Change request
1.3		03-July-2019	E. Thomas		BUG 15440 - SSA Sales & Service - SMS contact methodology setup
1.4		10-10-2019		Ben King		BUG 15581 change URL
1.5		24-10-2019		Chris Ledger	BUG 16689 - Comment Out V1.1 Changes. They weren't included in UAT and I can only guess they weren't on LIVE.
1.6		26-02-2020		E. Thomas		BUG 15441 - Updated recipientlist for Israel
*/

DECLARE @NOW DATETIME
SET @NOW = GETDATE()

SELECT  DISTINCT
		C.InternationalDiallingCode
        + CONVERT(NVARCHAR(100), CONVERT(BIGINT, dbo.udfReturnNumericsOnly(O.MobilePhone))) AS MobilePhone ,
        O.PartyID ,
        O.sType ,
        O.ID ,
        O.Password ,
        O.ccode ,
        O.lang ,
        O.etype ,
        O.[week] ,
        O.modelcode ,
        CONVERT(NVARCHAR(20),O.FullModel) AS FullModel,
		CONVERT(VARCHAR(10),@Now,121) AS SelectionDate,
		'https://feedback.tell-jlr.com/S/' +  O.Password AS URL, --v1.4
		O.Title,
		O.FirstName,
		O.Surname,
		O.EmailAddress,
		O.DearName,
		ET.EventType,
		CASE		--V1.6
			WHEN C.Country ='Israel' THEN 'IpsosRecipientList_' + c.ISOAlpha3 + '_' + REPLACE(O.STYPE,' ','') + '_' + ET.EventType + '_' + CONVERT(VARCHAR,ISNULL(O.lang,''))
			ELSE 'IpsosRecipientList_' + c.ISOAlpha3 + '_' + ET.EventType + '_' + CONVERT(VARCHAR,ISNULL(O.lang,''))
		END AS RecipientList
		
FROM    SelectionOutput.SMS AS O
        INNER JOIN ContactMechanism.Countries C ON C.CountryID = O.ccode
		INNER JOIN Sample.Event.EventTypes	ET ON O.etype = ET.EventTypeID	--V1.3
		--LEFT JOIN SelectionOutput.ReoutputCases R ON O.ID = R.CaseID		--V1.1	
		--WHERE R.CASEID IS NULL 												--V1.1