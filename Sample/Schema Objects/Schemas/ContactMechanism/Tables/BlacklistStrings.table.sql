CREATE TABLE ContactMechanism.BlacklistStrings (
    BlacklistStringID dbo.BlacklistStringID            IDENTITY (1, 1) NOT NULL,
    BlacklistString                   NVARCHAR(100) NOT NULL,
    Operator                          VARCHAR(50)   NOT NULL,
    BlacklistTypeID   dbo.BlacklistTypeID        NOT NULL,
    FromDate                          DATETIME2       NULL,
    Throughdate                       DATETIME2       NULL
);

