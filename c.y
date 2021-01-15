%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <ctype.h>
    #include "mytable.h"
    #include <string.h>

    static int flag=0;
    int yyerror(char *);
    int yylex(void);
    int yylineno;
    extern FILE * yyin;
    extern FILE *fopen(const char *filename, const char *mode);
    char* target, source;
    static int tempnum;
    
    char * newtemp();
    
    int istemp(char* c);
    
    void removetemp();
    void emitln(char *s);
    void emit(char *s);
    static int label = 0;
    
    char* openlabel();
    char* closelabelmin();
    char * closelabel();
    
    char * stack [100]; 
    static int top = 0;
    char * stack_pop();
    char * stack_get_top_element() ;
    void stack_push(char * c);
    static int stack_get_top();
    
       

    
  /////////////// TABDILE HAMECHI BE CHARECTOR  
    


%}




%token	PAR_OPEN  PAR_CLOSE COMMA SEMICOLON  WHILE RETURN FOR
%token	IF ELSE CB_OPEN CB_CLOSE PLUS MINUS ASTERISK SLASH ASSIGNMENT
%token	OR AND NOT LESS LESS_EQUAL MORE_EQUAL MORE EQUAL NOT_EQUAL QUOT


%union { char * intval;
        char  charval;
        struct symtab *symp;
        }
        
        
        

%token <intval> NUMBER
%token <charval> LITERAL_C
%token <symp> ID
%token <intval> CHAR
%token <intval> INT
%token <intval> VOID


%type <intval> expression
//%type <charval> char_expression   
%type <intval> conditions   
%type <intval> conditionsforwhile 
%type <intval> types
       



%left PLUS MINUS
%left ASTERISK SLASH

 
 
 
 
 
 


%%



program
    :program funcdef 
    | funcdef
    |
    ;

funcdef
    : types ID {printf ("%s :\n", $2->name);}args block_statement {if (flag==1){printf ("jr $ra\n");}flag =1;}
    ;

args
    :  PAR_OPEN var_def_list PAR_CLOSE
    ;
    
var_def_list
    :
	var_def
	|var_def COMMA var_def
	|var_def COMMA var_def COMMA var_def
	|var_def COMMA var_def COMMA var_def COMMA var_def
    |
    ;

    
var_def
    :   types ID
    ;

types
    : INT
    | VOID
    ;

block_statement
    :   CB_OPEN statements CB_CLOSE
    ;

statements
    : statements statement 
    | statement 
    |
    ;

statement
    : block_statement
    | conditional_statement
    | while_st
	| for_st
	| func_call SEMICOLON
    | assignment_statement SEMICOLON
    | ret_statement SEMICOLON
    ;
	
func_call:
	ID argcall {printf ("jal %s\n", $1->name);}
	;
	
argcall:
     PAR_OPEN NUMBER COMMA NUMBER COMMA NUMBER COMMA NUMBER PAR_CLOSE 
	 |PAR_OPEN NUMBER COMMA NUMBER COMMA NUMBER PAR_CLOSE
	 |PAR_OPEN NUMBER COMMA NUMBER PAR_CLOSE
	 |PAR_OPEN NUMBER PAR_CLOSE
	 |PAR_OPEN PAR_CLOSE
	 ;
	
	
conditional_statement
    
    : IF PAR_OPEN conditions {removetemp(tempnum);} PAR_CLOSE  block_statement {/*char *  myelse = closelabel();*/ char * myelse = stack_pop();char* endif = openlabel();stack_push(endif);printf("j %s ; \n%s : \n",stack_get_top_element(), myelse);} elsest {/*char* endelse = closelabel()*/;printf("%s : \n", stack_pop());} 
     ;

elsest
    : ELSE block_statement
    |
    ;
    
while_st 
    : WHILE PAR_OPEN conditionsforwhile  {removetemp(tempnum);} PAR_CLOSE  block_statement {/*char* a =closelabel()*/char * startwhile = stack_pop(); printf("j %s ;\n%s :\n",startwhile ,stack_pop());} 
    ;
	
for_st :
      FOR PAR_OPEN types ID SEMICOLON conditionsforwhile {removetemp(tempnum);} SEMICOLON assignment_statement PAR_CLOSE block_statement {/*char* a =closelabel()*/char * startwhile = stack_pop(); printf("j %s \n%s :\n",startwhile ,stack_pop());};
      |FOR PAR_OPEN ID SEMICOLON conditionsforwhile {removetemp(tempnum);} SEMICOLON assignment_statement PAR_CLOSE block_statement {/*char* a =closelabel()*/char * startwhile = stack_pop(); printf("j %s \n%s :\n",startwhile ,stack_pop());}	  
      |FOR PAR_OPEN assignment_statement SEMICOLON conditionsforwhile {removetemp(tempnum);} SEMICOLON assignment_statement PAR_CLOSE block_statement {/*char* a =closelabel()*/char * startwhile = stack_pop(); printf("j %s \n%s :\n",startwhile ,stack_pop());}
    
conditions 
    : conditions LESS expression {char *  myelse = openlabel(); stack_push(myelse);  printf("bgt $%s , $%s , %s \n",$1, $3, myelse );}
    | conditions LESS_EQUAL expression  {char *  myelse = openlabel(); stack_push(myelse);  printf("bge $%s , $%s , %s \n",$1, $3, myelse );}
    | conditions MORE_EQUAL expression {char *  myelse = openlabel(); stack_push(myelse);  printf("ble $%s , $%s , %s \n",$1, $3, myelse );}
    | conditions MORE expression {char *  myelse = openlabel(); stack_push(myelse);  printf("blt $%s , $%s , %s \n",$1, $3, myelse );}
    | conditions NOT_EQUAL expression {char *  myelse = openlabel(); stack_push(myelse);  printf("beq $%s , $%s , %s \n",$1, $3, myelse );}
    | conditions EQUAL expression {char *  myelse = openlabel(); stack_push(myelse);  printf("bnq $%s , $%s , %s \n",$1, $3, myelse );}
    | expression   //{ printf("%s = %s;\n",$$ = newtemp(), $1); removetemp();}
    ;

conditionsforwhile 
    : conditionsforwhile LESS expression {char * startwhile = openlabel(); char * endwhile = openlabel();stack_push(endwhile); stack_push(startwhile) ;printf("%s :\nbgt $%s , $%s , %s \n",startwhile , $1 , $3, endwhile);}
    | conditionsforwhile LESS_EQUAL expression {char * startwhile = openlabel(); char * endwhile = openlabel();stack_push(endwhile); stack_push(startwhile) ;printf("%s :\nbge $%s , $%s , %s \n",startwhile , $1 , $3, endwhile);}
    | conditionsforwhile MORE_EQUAL expression {char * startwhile = openlabel(); char * endwhile = openlabel();stack_push(endwhile); stack_push(startwhile) ;printf("%s :\nble $%s , $%s , %s  ; \n",startwhile , $1 , $3, endwhile);}
    | conditionsforwhile MORE expression {char * startwhile = openlabel(); char * endwhile = openlabel();stack_push(endwhile); stack_push(startwhile) ;printf("%s :\nblt $%s , $%s , %s \n",startwhile , $1 , $3, endwhile);}
    | conditionsforwhile NOT_EQUAL expression {char * startwhile = openlabel(); char * endwhile = openlabel();stack_push(endwhile); stack_push(startwhile) ;printf("%s :\nbeq $%s , $%s , %s \n",startwhile , $1 , $3, endwhile);}
    | conditionsforwhile EQUAL expression {char * startwhile = openlabel(); char * endwhile = openlabel();stack_push(endwhile); stack_push(startwhile) ;printf("%s :\nbnq $%s , $%s , %s\n",startwhile , $1 , $3, endwhile);}
    | expression   //{ printf("%s = %s;\n",$$ = newtemp(), $1); removetemp();}
    ;



 
assignment_statement
    : types ID ASSIGNMENT expression {/*if (!strcmp($1, "int"))*/printf("sw $%s , 0($%s)\n", $2 -> name, $4 ); $2 -> type = "int"; /*else{yyerror("type missmatch ; int assignment to char ; expected 'int' ");} */removetemp(tempnum);  }
    | ID ASSIGNMENT expression { /*if( !strcmp($1 -> type, "int"))*/printf("mov $%s , $s \n", $1 -> name, $3 );/*else{yyerror("type miss match ");}*/ removetemp(tempnum); }
    | types ID ASSIGNMENT NUMBER {/*if (!strcmp($1, "int"))*/printf("movi %s , %s \n", $2 -> name, $4 );$2 -> type = "char";/* else{yyerror("type missmatch ; char assignment to int expected 'char' ");} */removetemp(tempnum);  }  
    //| ID ASSIGNMENT char_expression 
    | types ID ASSIGNMENT {  }
    | error ; 
    ;
    
ret_statement
    : RETURN expression {  } 
    ;
    
expression
    : NUMBER { $$ = $1; }
    | ID { $$ = $1 -> name ;}
    | expression PLUS expression { printf("add $%s , $%s , $%s  \n", $$ = newtemp() ,$1 , $3 ) ; }
    | expression MINUS expression { printf("sub $%s , $%s , $%s  \n",$$ =newtemp() , $1 , $3 ) ;  }
    | expression ASTERISK expression { printf("mul $%s , $%s , $%s \n", $$ = newtemp() ,$1, $3 ); }
    | expression SLASH expression {if(strcmp($3,"0") == 0 ) {yyerror("Error! can't devide to zero");} printf("div $%s , $%s , $%s \n",$$ = newtemp() , $1, $3 ); }
   /* | PAR_OPEN expression PAR_CLOSE { printf("%s = ( %s ) ; \n",$$ = newtemp() , $2 ); }*/
    ;



%%

struct symtab * symlook(s)
char *s;
{
    char *p;
    struct symtab *sp;
    for(sp = symtab ; sp < &symtab[NSYMS] ; sp++){
        if (sp -> name && ! strcmp(sp->name, s)){
            return sp;
        }
        if (!sp -> name){
            sp->name = strdup(s);
            return sp;
            
        }
    
    }
    yyerror("too many symbols ");
    exit(1);
} 

char * openlabel (){
    label = label + 1;
    
    char integer_string[4] = "";
    
    sprintf(integer_string, "%d", label);
    char * temp ;
    temp = strdup("L");
    return  strcat(temp, integer_string); 

} 


void removetemp(int n){
    tempnum = tempnum - n;
}


char * newtemp(){
    tempnum = tempnum + 1;

    char integer_string[4] = "";
    
    sprintf(integer_string, "%d", tempnum);
    char * temp ;
    temp = strdup("T");
    return  strcat(temp, integer_string); 

}


void stack_push(char * c){
    stack[top++] = c;
}

char * stack_pop(){
    return stack[--top];
    
}

static int stack_get_top(){
    return top;

}

char * stack_get_top_element(){
    return stack[top - 1];

}





int yyerror(char *s){
    
    fprintf(stderr , "%s line %i \n", s, yylineno);
    exit(0);

}


int main(int argc ,char *argv[]){
    
    yyin = fopen(argv[1], "r");
    
    yyparse();
    
    fclose(yyin);
    return 0;
}

  
