ALTER DATABASE [$(DatabaseName)]
    ADD LOG FILE (NAME = [$(DatabaseName)_Log], FILENAME = '$(LogFilePath)$(DatabaseName)_Log.ldf', MAXSIZE = UNLIMITED, FILEGROWTH = 10 %);

