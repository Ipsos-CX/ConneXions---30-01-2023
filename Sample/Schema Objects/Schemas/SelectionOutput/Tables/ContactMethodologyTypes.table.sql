CREATE TABLE [SelectionOutput].[ContactMethodologyTypes] (
    [ContactMethodologyTypeID] dbo.ContactMethodologyTypeID          IDENTITY (1, 1) NOT NULL,
    [ContactMethodologyType]   VARCHAR (50) NOT NULL,
    [PostalOutput]             BIT          NOT NULL,
    [TelephoneOutput]          BIT          NOT NULL,
    [SMSOutput]				   BIT          NOT NULL
);

