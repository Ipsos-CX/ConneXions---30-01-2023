CREATE VIEW [SelectionOutput].[vwCATIBase]
AS
WITH LandLine AS (
	SELECT DISTINCT
		 CCM.CaseID
		,TN.ContactNumber
	FROM SelectionOutput.Base B
	INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = B.CaseID
	INNER JOIN ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = CCM.ContactMechanismID
	INNER JOIN ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = CM.ContactMechanismID
	INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CM.ContactMechanismTypeID
	WHERE CMT.ContactMechanismType = 'Phone (landline)'
),
Work AS (
	SELECT DISTINCT
		 CCM.CaseID
		,TN.ContactNumber
	FROM SelectionOutput.Base B
	INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = B.CaseID
	INNER JOIN ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = CCM.ContactMechanismID
	INNER JOIN ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = CM.ContactMechanismID
	INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CM.ContactMechanismTypeID
	WHERE CMT.ContactMechanismType = 'Phone'
),
Mobile AS (
	SELECT DISTINCT
		 CCM.CaseID
		,TN.ContactNumber
	FROM SelectionOutput.Base B
	INNER JOIN Event.CaseContactMechanisms CCM ON CCM.CaseID = B.CaseID
	INNER JOIN ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = CCM.ContactMechanismID
	INNER JOIN ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = CM.ContactMechanismID
	INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CMT.ContactMechanismTypeID = CM.ContactMechanismTypeID
	WHERE CMT.ContactMechanismType = 'Phone (mobile)'
)
SELECT DISTINCT
	CD.VIN,
	CD.DealerCode,
	B.ModelDescription AS ModelDesc,
	B.OrganisationName AS CoName, 
	ISNULL(PA.Street,'') AS Add1, 
	ISNULL(PA.SubLocality,'') AS Add2, 
	ISNULL(PA.Locality,'') AS Add3, 
	ISNULL(PA.Town,'') AS Add4, 
	ISNULL(PA.PostCode,'') AS Add5,
	P.ContactNumber AS LandPhone,
	W.ContactNumber AS WorkPhone,
	M.ContactNumber AS MobilePhone,
	B.PartyID,
	B.CaseID,
	GETDATE() AS DateOutput,
	B.ManufacturerPartyID AS JLR, 
	B.EventTypeID,
	B.RegistrationNumber AS RegNumber,
	Coalesce(CD.RegistrationDate,CD.EventDate) AS RegDate,
	ISNULL(CD.LastName + ' ' + CD.FirstName + ' ' + CD.SecondLastName, '') AS LocalName,
	B.EventDate,
	B.SelectionOutputPassword,
	B.GDDDealerCode, --v1.3
	B.ReportingDealerPartyID, --v1.3
	B.VariantID, --v1.3
	B.ModelVariant -- v1.3
FROM SelectionOutput.Base B
INNER JOIN Meta.CaseDetails CD ON CD.CaseID = B.CaseID
LEFT JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = B.PostalAddressContactMechanismID
LEFT JOIN LandLine P ON P.CaseID = B.CaseID
LEFT JOIN Work W ON W.CaseID = B.CaseID
LEFT JOIN Mobile M ON M.CaseID = B.CaseID;