#INCLUDE "PROTHEUS.CH"
/*{Protheus.doc} GERASPJ

Cria registro na SPJ para todos os turnos definidos nas v�riavies de acordo com uma tabela de hor�rio pr�-definida
@author Leandro Drumond
*/

User Function GERASPJ()
Local aSR6 		:= {}
Local aSPJ		:= {}
Local aTurno	:= {}
Local aTab		:= {}
Local nX 		:= 0
Local nY		:= 0
Local cModelo	:= "D MG    002"	//Filial e turno da SPJ que ter�o os hor�rios utilizados como padr�o 
Local cTurno	:= ""
Local cTnoIni	:= "011"			//Turno incicial para cria��o da SPJ
Local cTnoFim	:= "999"			//Turno final para cria��o da SPJ
Local cSemIni	:= "01"				//Semana inicial para gera��o dos dados (sequencia)
Local cSemFim	:= "09"				//Semana final para gera��o dos dados (sequencia) 
Local cSemana	:= ""

DbSelectArea("SR6")

If DbSeek(cModelo)
	aSR6 	:= SR6->(dbStruct())

	DbSelectArea("SPJ")
	DbSeek(cModelo)
	aSPJ := SPJ->(DbStruct())
	
	While SPJ->(!Eof() .and. PJ_FILIAL + PJ_TURNO == "D MG    002")
		aAdd(aTab,{})
		For nX := 1 to Len(aSPJ)
			aAdd(aTab[Len(aTab)],SPJ->&(aSPJ[nX,1]))
		Next nX
		SPJ->(DbSkip())
	EndDo
	
	cTurno := cTnoIni
	
	While cTurno <= cTnoFim
		cSemana := cSemIni
		While cSemana <= cSemFim
			For nX := 1 to Len(aTab)
				RecLock("SPJ",.T.)
				For nY := 1 to Len(aSPJ)
					SPJ->&(aSPJ[nY,1]) := aTab[nX,nY]
				Next nY
				SPJ->PJ_TURNO 	:= cTurno
				SPJ->PJ_SEMANA 	:= cSemana
				MsUnLock()
			Next nX
			cSemana := Soma1(cSemana)
		EndDo
		cTurno := Soma1(cTurno)
	EndDo
EndIf
	
Return Nil