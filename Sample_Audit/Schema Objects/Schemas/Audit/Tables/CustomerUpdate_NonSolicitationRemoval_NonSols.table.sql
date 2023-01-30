CREATE TABLE Audit.CustomerUpdate_NonSolicitationRemoval_NonSols
                           (id INT IDENTITY (1,1) NOT NULL,
                                  AuditItemID INT NOT NULL, 
                                  PartyID INT NOT NULL, 
                                  ContactMechanismId INT NULL, 
                                  NonSolicitationID INT NOT NULL, 
                                  NonSolType  VARCHAR (50) NOT NULL

)