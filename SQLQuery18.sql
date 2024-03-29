USE [BankKrd]
GO
/****** Объект:  StoredProcedure [dbo].[sp_BSSFreeDocScan]    Дата сценария: 12/06/2013 12:44:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		
-- Create date: 28.07.2010
-- Description:	Проверка поступивших писем произвольной формы и выполнение файла
-- В файл передаются параметры: ДатаВремя письма, Наименование Организации, Тема письма
-- =============================================
ALTER PROCEDURE [dbo].[sp_BSSFreeDocScan] 
@FNPath VARCHAR(1000),
@RECIP VARCHAR(5000),
@6600REC VARCHAR(500),
@6601REC VARCHAR(500),
@6602REC VARCHAR(500),
@6603REC VARCHAR(500),
@6604REC VARCHAR(500),
@6605REC VARCHAR(500),
@6606REC VARCHAR(500),
@6607REC VARCHAR(500),
@6608REC VARCHAR(500),
@6609REC VARCHAR(500),
@6610REC VARCHAR(500),
@6611REC VARCHAR(500),
@6612REC VARCHAR(500),
@6613REC VARCHAR(500),
@6614REC VARCHAR(500),
@6615REC VARCHAR(500),
@ADMIN VARCHAR(500),
@ADMIN_MESS VARCHAR(500)
AS
BEGIN
	
DECLARE @Name VARCHAR(1000)
DECLARE @Dat int
DECLARE @Tim INT
DECLARE @Doc VARCHAR(1000)
DECLARE @Sign1 VARCHAR(100)
DECLARE @DatTim datetime
--declare @v int
declare @s varchar(128)
declare @send varchar(1000)
declare @bod varchar(3000)
declare @sub varchar(1000)
declare @adrr varchar(1000)
declare @do varchar(1000)
declare @war varchar(1000)
declare @dd varchar(100)
declare @acc varchar(4)
declare @cust int
DECLARE @v1 INT
DECLARE @v2 INT
DECLARE @i INT
DECLARE @MyTableVar table(
    [NAMEFULL] text NULL,
	[DATECREATE] int NULL,
	[TIMECREATE] int NULL,
	[DOCNAME] text NULL,
	[DATETIMERECEIVE] datetime NULL,
	[CUSTID] int NULL,
	[SIGNUID1] text NULL)

	INSERT INTO @MyTableVar
           ([NAMEFULL]
           ,[DATECREATE]
           ,[TIMECREATE]
           ,[DOCNAME]
           ,[DATETIMERECEIVE]
		   ,[CUSTID]
		   ,[SIGNUID1])
	SELECT c.[NAMEFULL], a.[DATECREATE]
		,a.[TIMECREATE]
		,a.[DOCNAME]
		,a.[DATETIMERECEIVE]
		,a.[CUSTID]
		,a.[SIGNUID1]
	FROM [10.194.44.10].[BSSBank].[dba].[FREECLIENTDOC] a, [10.194.44.10].[BSSBank].[dba].[CUSTOMER] c
	WHERE (a.custid = c.custid) and 
	NOT EXISTS (
	SELECT b.[DATECREATE]
		,b.[TIMECREATE]
		,b.[DOCNAME]
		,b.[DATETIMERECEIVE]
	FROM [BankKrd].[dbo].[FREEDOCOLD] b
	WHERE (a.[DATECREATE]=b.[DATECREATE]) 
	and (a.[TIMECREATE]=b.[TIMECREATE]))
	set @i=1
	set @Sign1=''
	DECLARE Cur CURSOR SCROLL FOR
	SELECT [NAMEFULL]
           ,[DATECREATE]
           ,[TIMECREATE]
           ,[DOCNAME]
           ,[DATETIMERECEIVE]
		   ,[CUSTID]
		   ,[SIGNUID1]		 FROM @MyTableVar
	OPEN Cur
	FETCH NEXT FROM Cur INTO @Name, @Dat, @Tim, @Doc, @DatTim, @cust, @Sign1; 
	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		set @adrr = @6600REC
		set @do = ''
		set @war=''
		DECLARE Cur2 CURSOR SCROLL FOR
		SELECT substring(a.account,10,4) FROM [10.194.44.10].[BSSBank].[dba].[ACCOUNT] a WHERE @cust=a.custid and substring(a.account,6,3)='810'
		OPEN Cur2
		FETCH NEXT FROM Cur2 INTO @acc; 
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			set @do = @do+@acc+',' 
			if @acc = '6601' if @6601REC <> '' begin set @adrr = @adrr+'; '+@6601REC end
			if @acc = '6602' if @6602REC <> '' begin set @adrr = @adrr+'; '+@6602REC end
			if @acc = '6603' if @6603REC <> '' begin set @adrr = @adrr+'; '+@6603REC end
			if @acc = '6604' if @6604REC <> '' begin set @adrr = @adrr+'; '+@6604REC end
			if @acc = '6605' if @6605REC <> '' begin set @adrr = @adrr+'; '+@6605REC end
			if @acc = '6606' if @6606REC <> '' begin set @adrr = @adrr+'; '+@6606REC end
			if @acc = '6607' if @6607REC <> '' begin set @adrr = @adrr+'; '+@6607REC end
			if @acc = '6608' if @6608REC <> '' begin set @adrr = @adrr+'; '+@6608REC end
			if @acc = '6609' if @6609REC <> '' begin set @adrr = @adrr+'; '+@6609REC end
			if @acc = '6610' if @6610REC <> '' begin set @adrr = @adrr+'; '+@6610REC end
			if @acc = '6611' if @6611REC <> '' begin set @adrr = @adrr+'; '+@6611REC end
			if @acc = '6612' if @6612REC <> '' begin set @adrr = @adrr+'; '+@6612REC end
			if @acc = '6613' if @6613REC <> '' begin set @adrr = @adrr+'; '+@6613REC end
			if @acc = '6614' if @6614REC <> '' begin set @adrr = @adrr+'; '+@6614REC end
			if @acc = '6615' if @6615REC <> '' begin set @adrr = @adrr+'; '+@6615REC end
			/*set @adrr = 
				CASE @acc
					WHEN '6600' THEN @adrr
					WHEN '6601' THEN @adrr+'; '+@6601REC
					WHEN '6602' THEN @adrr+'; '+@6602REC
					WHEN '6603' THEN @adrr+'; '+@6603REC
					WHEN '6604' THEN @adrr+'; '+@6604REC
					WHEN '6605' THEN @adrr+'; '+@6605REC
					WHEN '6606' THEN @adrr+'; '+@6606REC
					WHEN '6607' THEN @adrr+'; '+@6607REC
					WHEN '6608' THEN @adrr+'; '+@6608REC
					WHEN '6609' THEN @adrr+'; '+@6609REC
					WHEN '6610' THEN @adrr+'; '+@6610REC
					WHEN '6611' THEN @adrr+'; '+@6611REC
					WHEN '6612' THEN @adrr+'; '+@6612REC
					WHEN '6613' THEN @adrr+'; '+@6613REC
					WHEN '6614' THEN @adrr+'; '+@6614REC
					WHEN '6615' THEN @adrr+'; '+@6615REC
				END*/
			FETCH NEXT FROM Cur2 INTO @acc;
		END
		CLOSE Cur2
		DEALLOCATE Cur2

		if (@Sign1 <> '') and (CONVERT(VARCHAR(500),@DatTim,113) <> '') begin
			set @war=''
			set @dd='['+CONVERT(VARCHAR(500),@DatTim,113)+']'
		end
		else begin
			set @war='1'--char(10)+char(10)+'ВАЖНО: Пришедшее письмо содержит глобальную ошибку, поэтому оно не отобразится в'+char(10)+'списке "произвольных документов в банк" - можете даже не искать!'+char(10)+'Необходимо, чтобы клиент занаво отправил копию этого письма!!!'+char(10)+'Данный сбой получения документа от клиента ОЧЕНЬ редкий, но иногда бывает :('
			set @dd='' 
		end
		if @war = '' begin
			set @FNPath=dbo.ReplaceChar(@FNPath) 
			set @Name=dbo.ReplaceChar(@Name)
			set @Doc=dbo.ReplaceChar(@Doc)
			--Запуск батника по указанному пути--
			set @s = @FNPath + ' ""' + @Name + '"" ""' + @Doc + '""'  --net send 10.194.32.38 [' + CONVERT(VARCHAR(500),@DatTim,131) + '] От клиента ' + @Name + ' пришло письмо с темой: ' + @Doc + '"'
			set @send = 'xp_cmdshell "'+ @s +'"'
			exec(@send)                             
			--Отправка мыла--
			set @bod = @dd+' В систему Банк-Клиент для ДО: '+@do+' от клиента "' + @Name + '" пришло письмо с темой: "' + @Doc + '"'
			set @sub = 'От клиента "'+@Name+'" пришло письмо с темой: "'+@Doc+'"'
			if @adrr = '' begin
				set @adrr = @ADMIN
				set @bod = @ADMIN_MESS+char(10)+char(10)+@bod
				set @sub = 'ОШИБКА ОТПРАВКИ ПИСЬМА с сервера SQL - '+@sub
			end
			EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'bankmail', 
			@recipients = @adrr,
			@copy_recipients = '',
			@body = @bod, /*'[' + CONVERT(VARCHAR(500),@DatTim,131) + '] В систему Банк-Клиент, от клиента ""' + @Name + '"" пришло письмо с темой: ""' + @Doc + '""'*/
			@subject = @sub, --'От клиента "'+@Name+'" пришло письмо с темой: "'+@Doc+'"',
			@body_format = 'TEXT';
			set @i=@i+1
		end 
		FETCH NEXT FROM Cur INTO @Name, @Dat, @Tim, @Doc, @DatTim, @cust, @Sign1;
	END
	CLOSE Cur
	DEALLOCATE Cur

SELECT @v1=COUNT(*) FROM [BankKrd].[dbo].[FREEDOCOLD]
SELECT @v2=COUNT(*) FROM @MyTableVar

If (@v1 > @v2) and (@war = '')
BEGIN
	DELETE FROM [BankKrd].[dbo].[FREEDOCOLD]
	INSERT INTO [BankKrd].[dbo].[FREEDOCOLD]
           ([NAMEFULL]
           ,[DATECREATE]
           ,[TIMECREATE]
           ,[DOCNAME]
           ,[DATETIMERECEIVE])
           SELECT b.[NAMEFULL], a.[DATECREATE]
			,a.[TIMECREATE]
			,a.[DOCNAME]
			,a.[DATETIMERECEIVE]	
			FROM [10.194.44.10].[BSSBank].[dba].[FREECLIENTDOC] a, [10.194.44.10].[BSSBank].[dba].[CUSTOMER] b
			Where a.custid = b.custid
			ORDER BY a.[DATECREATE]
END

END




