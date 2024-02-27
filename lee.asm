bits 32 ; assembling for the 32 bits architecture

; declare the EntryPoint (a label defining the very first instruction of the program)
global start        

; declare external functions needed by our program
extern exit,fread,fscanf,fopen,fclose,printf,scanf               ; tell nasm that exit exists even if we won't be defining it
import exit msvcrt.dll    ; exit is a function that ends the calling process. It is defined in msvcrt.dll
import fread msvcrt.dll 
import fscanf msvcrt.dll 
import fopen msvcrt.dll 
import fclose msvcrt.dll
import printf msvcrt.dll                          
import scanf msvcrt.dll ; msvcrt.dll contains exit, printf and all the other important C-runtime specific functions

; our data is declared here (the variables needed by our program)
segment data use32 class=data
    ; ...
    queue times 1000 dd 0
    matrix times 10000 db 0
    n dd 0
    dist dd 0
    current_x dd 0
    current_y dd 0
    queue_count dd 0
    x_sursa dd 0
    x_dest dd 0
    y_sursa dd 0
    y_dest dd 0
    mesaj_citire_x db "Dati x: ",0
    mesaj_citire_y db "Dati y: ",0
    format db "%d",0
    mesaj_sursa db "Introduceti coordonatele sursei:",10,13,0
    mesaj_destinatie db "Introduceti coordonatele destinatiei:",10,13,0
    mod_acces db "r",0
    fisier db "lee.txt",0
    descriptor dd 0
    directie_x dd -1,0,0,1
    directie_y dd 0,-1,1,0
    mesaj_solutie db "Distanta minima intre cele doua puncte este de %d unitati.",0
    mesaj_not_solutie db "Nu exista nicio cale intre cele doua puncte.",0

; our code starts here
segment code use32 class=code
    
    deschide_fisier:
        push dword mod_acces
        push dword fisier
        call [fopen]
        add esp,4*2
        cmp eax, 0
        je start.final
        mov [descriptor], eax
        ret
        
    citeste_matrice:
        push dword n
        push dword format
        push dword [descriptor]
        call [fscanf]
        add esp, 4*3
        
        push dword [descriptor]
        push dword 10000
        push dword 1
        push dword matrix
        call [fread]
        add esp, 4*4
        ret
        
    inchide_fisier:
        push dword [descriptor]
        call [fclose]
        add esp, 4
        ret
        
    afiseaza_solutie:
        push dword [dist]
        cmp dword [dist], -1
        jne .solutie_gasita
        push dword mesaj_not_solutie
        jmp .afisare
        .solutie_gasita:
        push dword mesaj_solutie
        .afisare:
        call [printf]
        add esp, 4*2
        ret
        
    citeste_coordonate:
        push dword mesaj_sursa
        call [printf]
        add esp, 4
        
        push dword mesaj_citire_x
        call [printf]
        add esp, 4
        
        push dword x_sursa
        push dword format
        call [scanf]
        add esp, 4*2
        
        push dword mesaj_citire_y
        call [printf]
        add esp, 4
        
        push dword y_sursa
        push dword format
        call [scanf]
        add esp, 4*2
        
        push dword mesaj_destinatie
        call [printf]
        add esp, 4
        
        push dword mesaj_citire_x
        call [printf]
        add esp, 4
        
        push dword x_dest
        push dword format
        call [scanf]
        add esp, 4*2
        
        push dword mesaj_citire_y
        call [printf]
        add esp, 4
        
        push dword y_dest
        push dword format
        call [scanf]
        add esp, 4*2       
        ret
        
    extract_queue:
        mov eax, [queue]
        mov [dist], eax
        mov eax, [queue+4]
        mov [current_x], eax
        mov eax, [queue+8]
        mov [current_y], eax
        mov ecx, 0
        .repeta:
            push ecx
            mov eax, ecx
            mov dx, 12
            mul dx
            mov ecx, eax
            mov edx, eax
            add edx, 12
            mov eax, [edx+queue]
            mov [ecx+queue], eax
            mov eax, [edx+queue+4]
            mov [ecx+queue+4], eax
            mov eax, [edx+queue+8]
            mov [ecx+queue+8], eax
            pop ecx
            inc ecx
            mov eax, [queue_count]
            cmp ecx, eax
            je .gata
            jmp .repeta
        .gata:
        mov eax, ecx
        mov dx, 12
        mul dx
        mov [eax+queue], dword 0
        mov [eax+queue+4], dword 0
        mov [eax+queue+8], dword 0
        dec dword [queue_count]
        ret
            
    verif:
        mov eax, [current_x]
        mov ebx, [current_y]
        add eax, [ecx*4+directie_x-4]
        add ebx, [ecx*4+directie_y-4]
        mov edx, [n]
        dec edx
        cmp eax, 0
        jl .not_valid
        cmp eax, edx
        jg .not_valid
        cmp ebx, 0
        jl .not_valid
        cmp ebx, edx
        jg .not_valid
        push ebx
        push eax
        mov eax, ebx
        mul word [n]
        inc eax
        add eax, ebx
        mov ebx, eax
        pop eax
        mov cl, [eax+ebx+matrix]
        pop ebx
        cmp cl, "#"
        je .not_valid
        cmp cl, "1"
        je .not_valid
        mov edx, 1
        ret
        .not_valid:
        mov edx, 0
        ret
         
    lee:
        mov dword [queue], 0
        mov eax, [x_sursa]
        mov [queue+4], eax
        mov eax, [y_sursa]
        mov [queue+8], eax        
        inc dword [queue_count]
        .repeat:
            push ecx
            call extract_queue
            pop ecx
            mov eax, [current_x]
            mov ebx, [current_y]
            push ebx
            push eax
            mov eax, ebx
            mul word [n]
            inc eax
            add eax, ebx
            mov ebx, eax
            pop eax
            mov byte [eax+ebx+matrix], "1"
            pop ebx
            cmp eax, [x_dest]
            jne .nu_e_destinatie
            cmp ebx, [y_dest]
            jne .nu_e_destinatie
            jmp .destinatie
            .nu_e_destinatie:
            mov ecx, 4
            .parcurge:
                push ecx
                call verif
                pop ecx
                cmp edx, 0
                je .nu_se_adauga
                mov edx, [dist]
                inc edx
                push ecx
                push ebx
                mov ebx, [queue_count]
                push eax
                push edx
                mov eax,ebx
                mov dx, 12
                mul dx
                mov ecx, eax
                pop edx
                pop eax
                pop ebx
                mov [ecx+queue], edx
                mov [ecx+queue+4], eax
                mov [ecx+queue+8], ebx
                inc dword [queue_count]
                pop ecx
                .nu_se_adauga:
                loop .parcurge
            cmp dword [queue_count], 0
            je .done
            jmp .repeat
        .destinatie:
        ret
        .done:
        mov dword [dist], -1
        ret
        
    start:
        call deschide_fisier
        call citeste_matrice
        call inchide_fisier
        call citeste_coordonate
        call lee
        call afiseaza_solutie
        .final:
        push    dword 0      ; push the parameter for exit onto the stack
        call    [exit]       ; call exit to terminate the program
