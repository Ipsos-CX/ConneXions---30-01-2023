CREATE TRIGGER [ContactMechanism].[TR_IU_ContactMechanism_PostalAddresses]
   ON [ContactMechanism].[PostalAddresses]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- RECALCULATE THE AddressChecksum VALUE
    
    UPDATE PA
    SET PA.AddressChecksum = [$(ETLDB)].dbo.udfGenerateAddressChecksum(I.BuildingName, I.SubStreetNumber, I.SubStreet, I.StreetNumber, I.Street, I.SubLocality, I.Locality, I.Town, I.Region, I.PostCode, I.CountryID)
    FROM ContactMechanism.PostalAddresses PA
    INNER JOIN INSERTED I ON I.ContactMechanismID = PA.ContactMechanismID
    INNER JOIN DELETED D ON D.ContactMechanismID = I.ContactMechanismID
    WHERE ISNULL(I.AddressChecksum, 0) = ISNULL(D.AddressChecksum, 0) -- WHERE WE'RE NOT SPECIFICALLY SETTING THE AddressChecksum VALUE, I.E. WHERE AddressChecksum IN THE INSERTED TABLE IS NOT DIFFERENT TO THE VALUE ALREADY THERE
    

END