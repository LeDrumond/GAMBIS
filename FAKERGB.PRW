#INCLUDE "PROTHEUS.CH"
/*{Protheus.doc} FakeRGB

Esta fun��o ir� criar um lan�amento na RGB para cada funcion�rio encontrado de acordo com o filtro definido nas vari�veis abaixo.
N�o tem interface com usu�rio.
 
@author Leandro Drumond
*/

User Function FakeRGB()
Local cProcesso := "06969"			//Processo dos funcion�rios para os quais ser�o criados os registros na RGB
Local cPeriodo	:= "201711"			//Per�odo em que ser�o criados os lan�amentos
Local cRoteiro	:= "AUT"			//Roteiro onde ser�o criados os lan�amentos
Local cSemana	:= "01"				//Semana onde ser�o criados  os lan�amentos
Local cFilAux	:= "D MG 01 "		//Filial dos funcion�rios
Local cVerba	:= "191"			//C�digo da verba que ser� criada
Local dDataRef	:= StoD("20171130") //Data de refer�ncia do lan�amento
Local nValor	:= 5000				//Valor atribu�do a verba
Local nPula   	:= 8
Local nEspaco 	:= 8
Local nReg	  	:= 0
Local cAliasQry := GetNExtAlias()

BeginSql alias cAliasQry
	SELECT *
	FROM 		%table:SRA% SRA
	WHERE RA_PROCES = %exp:cProcesso% AND RA_FILIAL = %exp:cFilAux%
	ORDER BY RA_MAT				
EndSql

While (cAliasQry)->( !Eof() )
	If nPula == nEspaco
		nPula := 0
		RecLock("RGB",.T.)
		RGB->RGB_FILIAL := (cAliasQry)->( RA_FILIAL )
		RGB->RGB_MAT    := (cAliasQry)->( RA_MAT )
		RGB->RGB_PROCES := (cAliasQry)->( RA_PROCES )
		RGB->RGB_PERIOD := cPeriodo
		RGB->RGB_ROTEIR := cRoteiro
		RGB->RGB_SEMANA := cSemana
		RGB->RGB_PD		:= cVerba
		RGB->RGB_TIPO1  := "V"
		RGB->RGB_VALOR	:= nValor
		RGB->RGB_DTREF	:= dDataRef
		RGB->RGB_CC		:= (cAliasQry)->( RA_CC )
		RGB->RGB_TIPO2	:= "G"
		RGB->(MsUnLock())
		nReg++
		Conout("Registro " + AllTrim(Str(nReg)) + " criado.")  
	EndIf
	nPula++
	(cAliasQry)->( DbSkip() )
EndDo

(cAliasQry)->( DbCloseArea() )

Return Nil