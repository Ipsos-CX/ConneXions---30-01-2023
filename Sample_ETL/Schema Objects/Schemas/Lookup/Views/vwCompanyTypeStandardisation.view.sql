CREATE VIEW Lookup.vwCompanyTypeStandardisation WITH SCHEMABINDING

AS

/*
	Purpose:	Compile a list of Standard company types and their known variances
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.vwSTANDARDISE_CompanyTypes

*/

	SELECT
		C.CompanyTypeID,
		C.CountryID,
		C.CompanyType AS Standard,
		CV.CompanyTypeVariance AS Variant 
	FROM Lookup.CompanyTypeWords C
	INNER JOIN Lookup.CompanyTypeWordVariances CV ON C.CompanyTypeID = CV.CompanyTypeID






