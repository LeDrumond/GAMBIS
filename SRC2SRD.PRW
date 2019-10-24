#INCLUDE "PROTHEUS.CH"
/*{Protheus.doc} MvSRCtoSRD

Cria registros na SRD baseado nos registros da SRC

@author Leandro Drumond
*/
User Function MvSRCtoSRD()
Local aArea 		:= GetArea()
Local cAliasSRC		:= GetNextAlias()
Local cPerIni		:= "201612"			//Período inicial para criação dos dados na SRD
Local cPerFim		:= "201712"			//Último período no qual serão criados registros na SRD
Local cProcesso		:= "06969"			//Processo para filtrar a SRC
Local cPeriodo		:= ""

DbSelectArea("SRD")
DbSetOrder(1)

BeginSql alias cAliasSRC
	SELECT 		*
	FROM 		%table:SRC% SRC
	WHERE SRC.%NotDel% AND 
	RC_PROCES = %exp:cProcesso%
	ORDER BY RC_FILIAL,RC_MAT				
EndSql

cMat   := ""

While (cAliasSRC)->(!Eof())
	cPeriodo := cPerIni
	While cPeriodo <= cPerFim
		RecLock("SRD",.T.)
		SRD->RD_FILIAL	:= (cAliasSRC)->RC_FILIAL
		SRD->RD_MAT		:= (cAliasSRC)->RC_MAT
		SRD->RD_PD		:= (cAliasSRC)->RC_PD
		SRD->RD_TIPO1	:= (cAliasSRC)->RC_TIPO1
		SRD->RD_HORAS	:= (cAliasSRC)->RC_HORAS
		SRD->RD_VALOR	:= (cAliasSRC)->RC_VALOR
		SRD->RD_CC		:= (cAliasSRC)->RC_CC
		SRD->RD_TIPO2	:= (cAliasSRC)->RC_TIPO2
		SRD->RD_SEQ		:= (cAliasSRC)->RC_SEQ
		SRD->RD_PROCES	:= (cAliasSRC)->RC_PROCES
		SRD->RD_ROTEIR	:= (cAliasSRC)->RC_ROTEIR
		SRD->RD_SEMANA	:= (cAliasSRC)->RC_SEMANA
		SRD->RD_PERIODO	:= cPeriodo
		SRD->RD_DATARQ 	:= cPeriodo
		If cPeriodo == "201612"
			cPeriodo := "201701"
		Else
			cPeriodo := Soma1(cPeriodo)
		EndIf
		SRD->RD_DATPGT := StoD(cPeriodo + "05")
		MsUnLock()
	EndDo
	(cAliasSRC)->(DbSkip())
EndDo

(cAliasSRC)->(DbCloseArea())

RestArea(aArea)

Return Nil