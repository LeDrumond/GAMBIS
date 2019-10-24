#INCLUDE "PROTHEUS.CH"
/*{Protheus.doc} FakeRGB

Esta função irá criar um lançamento na RGB para cada funcionário encontrado de acordo com o filtro definido nas variáveis abaixo.
Não tem interface com usuário.
 
@author Leandro Drumond
*/

User Function FakeRGB()
Local cProcesso := "06969"			//Processo dos funcionários para os quais serão criados os registros na RGB
Local cPeriodo	:= "201711"			//Período em que serão criados os lançamentos
Local cRoteiro	:= "AUT"			//Roteiro onde serão criados os lançamentos
Local cSemana	:= "01"				//Semana onde serão criados  os lançamentos
Local cFilAux	:= "D MG 01 "		//Filial dos funcionários
Local cVerba	:= "191"			//Código da verba que será criada
Local dDataRef	:= StoD("20171130") //Data de referência do lançamento
Local nValor	:= 5000				//Valor atribuído a verba
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