#INCLUDE "PROTHEUS.CH"

/*{Protheus.doc} GeraCPFVld

Gera um CPF válido

@author Leandro Drumond
*/

User Function GeraCPFVld()
Local aCpf1		:= Array(9,3)
Local aCpf2 	:= Array(10,3)
Local cCpf		:= ""
Local nX 		:= 0
Local nAux		:= 11
Local nTotAux	:= 0
Local nDig1 	:= 0
Local nDig2 	:= 0

For nX :=1 to 9
	aCpf1[nX,1] := Randomize(0,9) 
	aCpf1[nX,2] := nAux - nX
	aCpf1[nX,3] := aCpf1[nX,2] * aCpf1[nX,1]
	nTotAux += aCpf1[nX,3]   
Next nX

nDig1 := nTotAux % 11

If nDig1 < 2
	nDig1 := 0
Else
	nDig1 := 11 - nDig1
EndIf

nTotAux := 0

For nX := 1 to 9
	aCpf2[nX,1] := aCpf1[nX,1]
	aCpf2[nX,2] := aCpf1[nX,2]+1
	aCpf2[nX,3] := aCpf2[nX,2] * aCpf2[nX,1]
	nTotAux += aCpf2[nX,3] 
Next nX

aCpf2[10,1] := nDig1
aCpf2[10,2] := 2
aCpf2[10,3] := aCpf2[10,2] * aCpf2[10,1]
nTotAux += aCpf2[10,3]

nDig2 := nTotAux % 11

If nDig2 < 2
	nDig2 := 0
Else
	nDig2 := 11 - nDig2
EndIf

For nX := 1 to 9
	cCpf += AllTrim(Str(aCpf1[nX,1]))
Next nX

cCpf += AllTrim(Str(nDig1)) + AllTrim(Str(nDig2))

Return cCpf