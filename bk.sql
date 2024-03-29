USE [BankKrd]
GO
/****** Объект:  StoredProcedure [dbo].[sp_ScanZavisPP]    Дата сценария: 12/06/2013 12:28:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		
-- Create date: <04.03.2011>
-- Description:	<Сканирует таблицу ПП Банк-Клиента на наличие зависших в статусе выгружен>
-- =============================================
ALTER PROCEDURE [dbo].[sp_ScanZavisPP] 
@FNPath VARCHAR(1000),
@RECIP VARCHAR(1000),
@COPYRECIP VARCHAR(1000),
@STATUS int,
@STATUSNAME VARCHAR(100)
AS
BEGIN
declare @v integer
declare @s varchar(500)
declare @send varchar(500)
declare @s1 varchar(8000)
declare @s2 varchar(1000)
declare @s3 varchar(15)
declare @s4 varchar(1000)
declare @s5 varchar(8000)
declare @s6 varchar(8000)
declare @datr datetime
declare @datd datetime
declare @docn varchar(15)
declare @pay varchar(160)
declare @payacc varchar(25)
declare @amo float
declare @per varchar(300)
declare @per2 varchar(300)
declare @per3 varchar(300)
declare @ddd varchar(100)
declare @m integer
declare @i integer
SELECT @v = Count(*), @m = max(len(payer)) FROM [10.194.44.10].BSSBank.dba.paydocru
WHERE CONVERT(VARCHAR(20),getdate(),112) = CONVERT(VARCHAR(20),datetimereceive,112)
and CONVERT(VARCHAR(20),dateadd(minute,-20,getdate()),108) > CONVERT(VARCHAR(20),datetimereceive,108)
and STATUS = @STATUS

DECLARE Cur2 CURSOR SCROLL FOR
SELECT	 [DATETIMERECEIVE]
		,[DOCUMENTDATE]
		,[DOCUMENTNUMBER]
		,[PAYER]
		,[PAYERACCOUNT]
		,[AMOUNT]		
 FROM [10.194.44.10].BSSBank.dba.paydocru
WHERE CONVERT(VARCHAR(20),getdate(),112) = CONVERT(VARCHAR(20),datetimereceive,112)
and CONVERT(VARCHAR(20),dateadd(minute,-20,getdate()),108) > CONVERT(VARCHAR(20),datetimereceive,108)
and STATUS = @STATUS
set @per =  '                                                                                                                                                                                                                                                              '
set @per2 = '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
set @per3 = '______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________'
set @s4='--'
set @s5=''
set @i=1
OPEN Cur2
FETCH NEXT FROM Cur2 INTO @datr,@datd,@docn,@pay,@payacc,@amo; 
WHILE (@@FETCH_STATUS = 0)
BEGIN
	set @pay = dbo.ReplaceChar(@pay)
	set @ddd = CONVERT(VARCHAR(500),@datr,113)
	set @s4 = '| '+ LTRIM(str(@i))+substring(@per,1,(2-len(@i)))+' |'+@ddd+' |'+ @docn +substring(@per,1,(6-len(@docn)))+ ' | '+@pay+substring(@per,1,(@m-len(@pay)))+' | '+@payacc+' | '+str(@amo)+' |'
	set @s5 = @s5+ char(10) + @s4
	set @i=@i+1
	FETCH NEXT FROM Cur2 INTO @datr,@datd,@docn,@pay,@payacc,@amo;
END
CLOSE Cur2
DEALLOCATE Cur2
--set @s5 = @s5+substring(@per2,1,len(@s4)-1)
if len(@s4) > 1 begin
	set @s6 = ' '+substring(@per3,1,len(@s4)-2)+@s5+char(10)+' '+substring(@per2,1,len(@s4)-2)
end
--print @s5
set @s3 = 
CASE @v%10
	WHEN 1 THEN 'платёжка ЗАВИСЛА'
	WHEN 2 THEN 'платёжки ЗАВИСЛИ'
	WHEN 3 THEN 'платёжки ЗАВИСЛИ'
	WHEN 4 THEN 'платёжки ЗАВИСЛИ'
	ELSE 'платёжек ЗАВИСЛО'
END				
/*set @s = 'xp_cmdshell "net send 10.194.44.10 В Банк-Клиенте ' + str(@v) + ' '+@s3+' ЗАВИСЛИ В СТАТУСЕ ВЫГРУЖЕН!"'
if @v > 0 exec(@s)
set @s = 'xp_cmdshell "net send 10.194.32.36 В Банк-Клиенте ' + str(@v) + ' '+@s3+' ЗАВИСЛИ В СТАТУСЕ ВЫГРУЖЕН!"'
if @v > 0 exec(@s)
set @s = 'xp_cmdshell "net send 10.194.32.37 В Банк-Клиенте ' + str(@v) + ' '+@s3+' ЗАВИСЛИ В СТАТУСЕ ВЫГРУЖЕН!"'
if @v > 0 exec(@s)*/
--set @s = 'xp_cmdshell "net send 10.194.32.38 В Банк-Клиенте ' + str(@v) + ' '+@s3+' ЗАВИСЛИ В СТАТУСЕ ВЫГРУЖЕН!"'
if @v > 0 begin
	set @s = @FNPath + ' ""' + str(@v) + '"" ""' + @s3 + '"" ""'+@STATUSNAME+'""'  --net send 10.194.32.38 [' + CONVERT(VARCHAR(500),@DatTim,131) + '] От клиента ' + @Name + ' пришло письмо с темой: ' + @Doc + '"'
	set @send = 'xp_cmdshell "'+ @s +'"'
	exec(@send)
end
if @v > 0 begin
	set @s1 = '['+CONVERT(VARCHAR(500),GETDATE(),113)+'] '+'В Банк-Клиенте '+str(@v) +' '+@s3+' В СТАТУСЕ '+@STATUSNAME+'! Проверь БИСмарка'+char(10)+@s6
	set @s2 = 'В Банк-Клиенте '+str(@v) +' '+@s3+' В СТАТУСЕ '+@STATUSNAME+'! Проверь БИСмарка'
	EXEC msdb.dbo.sp_send_dbmail
	@profile_name = 'bankmail', 
	@recipients = @RECIP,
	@copy_recipients = @COPYRECIP,
	@body = @s1,
	@subject = @s2,
	@body_format = 'TEXT';
end
END
