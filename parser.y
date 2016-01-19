%{
extern "C"
{
	#include <stdio.h>
	#include <stdlib.h>
	
	extern int linenum;		/* declared in lex.l */
	extern FILE *yyin;		/* declared by lex */
	extern char *yytext;		/* declared by lex */
	extern char buf[256];		/* declared in lex.l */
	extern char trust_str[256];
	extern int Opt_D;
	
	int yyparse(void);	/* declared by yacc */
	int yylex(void);
	
	int yywrap()
	{
		return 1;
	}
	
	int yyerror( char *msg )
	{
		(void) msg;
		fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
		fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
		fprintf( stderr, "|\n" );
		fprintf( stderr, "| Unmatched token: %s\n", yytext );
		fprintf( stderr, "|--------------------------------------------------------------------------\n" );
		exit(-1);
	}
}
	
#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <string>
#include <vector>
using namespace std;

struct entry
{
	int kind; 						//program:1, function:2, parameter:3, variable:4, constant:5	
	int level;
	vector< pair<int, int> > type;	//void:0, integer:1, real:2, bool:3, string:4, array:5
	vector< string > attribute;		
};

vector< map<string, entry> > s(1);
vector<string> input;
vector<int> param;
string input_file;

void print_kind(int n)
{
    switch( n )
    {
        case 1: printf("%-11s\t", "program"); break;
        case 2: printf("%-11s\t", "function"); break;
        case 3: printf("%-11s\t", "parameter"); break;
        case 4: printf("%-11s\t", "variable"); break;
        case 5: printf("%-11s\t", "constant"); break;
        default:printf("%-11s\t", "error kind!"); break;
    }
}

string return_kind(int n)
{
	switch( n )
    {
        case 1: return "program"; break;
        case 2: return "function"; break;
        case 3: return "parameter"; break;
        case 4: return "variable"; break;
        case 5: return "constant"; break;
    }
}

void print_type(vector< pair<int, int> >& v)
{
    switch(v[0].first)
    {
        case 0: printf("%-17s\t", "void"); break;
        case 1: printf("%-17s\t", "integer"); break;
        case 2: printf("%-17s\t", "real"); break;
        case 3: printf("%-17s\t", "boolean"); break;
        case 4: printf("%-17s\t", "string"); break;
        case 5:
        {
            string tmp ="";
            for(int i=1; i<v.size(); i++)
            {
                tmp = tmp + "[" + to_string(v[i].first);
                if( v[i].first<v[i].second )
                    tmp =  tmp + ":" + to_string(v[i].second) + "]";
                else
                    tmp = tmp + "]";
            }
            switch(v[0].second)
            {
                case 1: tmp = "integer" + tmp; break;
                case 2: tmp = "real" + tmp; break;
                case 3: tmp = "boolean" + tmp; break;
                case 4: tmp = "string" + tmp; break;
                default:tmp = "array type error"; break;
            }
            printf("%-17s\t", tmp.c_str());
            break;
        }
        default: printf("%-17s\t", "error type!"); break;
    }
}

string return_type(vector< pair<int, int> > v)
{
	switch(v[0].first)
    {
        case 0: return "void"; break;
        case 1: return "integer"; break;
        case 2: return "real"; break;
        case 3: return "boolean"; break;
        case 4: return "string"; break;
        case 5:
        {
            string tmp ="";
            for(int i=1; i<v.size(); i++)
            {
                tmp = tmp + "[" + to_string(v[i].first);
                if( v[i].first<v[i].second )
                    tmp =  tmp + ":" + to_string(v[i].second) + "]";
                else
                    tmp = tmp + "]";
            }
            switch(v[0].second)
            {
                case 1: tmp = "integer" + tmp; break;
                case 2: tmp = "real" + tmp; break;
                case 3: tmp = "boolean" + tmp; break;
                case 4: tmp = "string" + tmp; break;
            }
            return tmp;
            break;
        }
    }
}

string return_type2(int t)
{
	switch (t)
	{
		case 1:
			return "INTEGER";
		break;
		case 2:
			return "REAL";
		break;
		case 3:
			return "BOOLEAN";
		break;
		case 4:
			return "STRING";
		break;
		case 5:
			return "ARRAY";
		break;
	}
}

int type_config(string s)
{
    if( s=="INTEGER" || s=="integer" )
        return 1; 
    if( s=="REAL" || s=="real" )
        return 2;
    if( s=="BOOLEAN" || s=="boolean" )
        return 3;
    if( s=="STRING" || s=="string" )
        return 4;
	if( s=="ARRAY" || s=="array" )
        return 4;
	return 0;
}

int type_config2(string s)
{
	size_t pos = s.find( "integer" );
	if( pos==0 )
		return 1;
	pos = s.find( "real" );
	if( pos==0 )
		return 2;
	pos = s.find( "boolean" );
	if( pos==0 )
		return 3;
	pos = s.find( "string" );
	if( pos==0 )
		return 4;
	return 0; 
}

bool check_param(string func_name, vector<string>& attr, vector<int>& tmp)
{
	bool flag = 1;
	for(int i=0; i<attr.size() && i<tmp.size(); i++)
	{
		if( type_config2(attr[i])!=tmp[tmp.size()-i-1] )
		{
			if( type_config2(attr[i])==2 )
			{
				if( tmp[tmp.size()-i-1]!=1 )
				{
					flag =0;
					cout<<"<Error> found in Line "<<linenum<<": in "<<func_name<<" the "<<i+1<<"th parameter type different"<<endl;
				}
			}
			else
			{
				flag =0;
				cout<<"<Error> found in Line "<<linenum<<": in "<<func_name<<" the "<<i<<"th parameter type different"<<endl;
			}
		}
	}
	if( attr.size()<tmp.size() )
	{
		cout<<"<Error> found in Line "<<linenum<<": in "<<func_name<<", pass in too many parameter."<<endl;
		flag = 0;
	}
	if( attr.size()>tmp.size() )
	{
		cout<<"<Error> found in Line "<<linenum<<": in "<<func_name<<", lose some parameter."<<endl;
		flag = 0;
	}
	return flag;
}

void dumpsymbol()
{
	if( !Opt_D )
		return; 
	
	for(int i=0;i< 110;i++)
        printf("=");
    printf("\n");
	printf("%-32s\t%-11s\t%-11s\t%-17s\t%-11s\t\n","Name","Kind","Level","Type","Attribute");
    for(int i=0;i< 110;i++)
        printf("-");
    printf("\n");

    for( map<string, entry>::iterator it=s[s.size()-1].begin(); it!=s[s.size()-1].end(); it++)
    {
        printf("%-32s\t", it->first.c_str());
        print_kind( it->second.kind );
        if( it->second.level==0 )
            printf("%d%-10s\t", it->second.level,"(global)");
        else
            printf("%d%-10s\t", it->second.level,"(local)");
        print_type( it->second.type );
        for(int i=0; i<it->second.attribute.size(); i++)
        {
            if( i )
                printf(", ");
            printf("%s", it->second.attribute[i].c_str());
        }
        printf("\n");
    }
	
    for(int i=0;i< 110;i++)
        printf("=");
    printf("\n");
}

 
%}

%union
{
	int num;
	double f_num;
	char *str;
}

/* tokens */
%token ARRAY
%token BEG
%token BOOLEAN
%token DEF
%token DO
%token ELSE
%token END
%token FALSE
%token FOR
%token INTEGER
%token IF
%token OF
%token PRINT
%token READ
%token REAL
%token RETURN
%token STRING
%token THEN
%token TO
%token TRUE
%token VAR
%token WHILE

%token ID
%token OCTAL_CONST
%token INT_CONST
%token FLOAT_CONST
%token SCIENTIFIC
%token STR_CONST

%token OP_ADD
%token OP_SUB
%token OP_MUL
%token OP_DIV
%token OP_MOD
%token OP_ASSIGN
%token OP_EQ
%token OP_NE
%token OP_GT
%token OP_LT
%token OP_GE
%token OP_LE
%token OP_AND
%token OP_OR
%token OP_NOT

%token MK_COMMA
%token MK_COLON
%token MK_SEMICOLON
%token MK_LPAREN
%token MK_RPAREN
%token MK_LB
%token MK_RB

/* start symbol */
%start program
%%

program		: ID { input.push_back(trust_str); } MK_SEMICOLON
				{
					struct entry e;
					e.kind = 1;
					e.level = s.size()-1;
					e.type.push_back( pair<int, int>(0, 0) );
					s[s.size()-1].insert( pair<string, entry>(input.back(), e) );
				}
			program_body END ID 
				{
					if( input.back()==trust_str ) 
					{
						if( input.back()+".p"!=input_file )
							cout<<"<Error> found in Line "<<linenum<<": program ID is different to source code file name."<<endl;
					}
					else
					{
						cout<<"<Error> found in Line "<<linenum<<": different program ID declaration."<<endl;				
					}
					input.pop_back();
					dumpsymbol();
					s.pop_back();	
				}
			;

program_body	: opt_decl_list opt_func_decl_list compound_stmt
			;

opt_decl_list	: decl_list
			| /* epsilon */
			;

decl_list	: decl_list decl
			| decl
			;

decl		: VAR id_list MK_COLON scalar_type MK_SEMICOLON       /* scalar type declaration */
				{
					struct entry e;
					e.kind = 4;
					e.level = s.size()-1;
					e.type.push_back( pair<int, int>(type_config( input.back() ), 0) );
					input.pop_back();
					for(int i=0; i<$<num>2; i++)
					{
						map<string, entry>::iterator it = s[s.size()-1].find( input.back() );
						if( it!=s[s.size()-1].end() )
							cout<<"<Error> found in Line "<<linenum<<": same ID '"<<input.back()<<"' redeclared."<<endl;
						else
							s[s.size()-1].insert( pair<string, entry>(input.back(), e) );
						input.pop_back();
					}
				}
			| VAR id_list MK_COLON array_type MK_SEMICOLON        /* array type declaration */
				{
					bool flag = 1;
					struct entry e;
					e.kind = 4;
					e.level = s.size()-1;
					e.type.push_back( pair<int, int>( 5, type_config(input.back()) ) );
					input.pop_back();
					
					vector< pair<int, int> > tmp;
					while( input.size()>=3 && input[input.size()-3]=="ARRAY" )
					{	
						int from, to;
						to = stoi( input.back(), nullptr, 10);
						input.pop_back();
						from = stoi( input.back(), nullptr, 10);
						input.pop_back();						
						tmp.push_back( pair<int, int>(from, to) );
						input.pop_back();
					}
					
					for(int i=tmp.size()-1; i>=0; i--)
					{
						if( tmp[i].first>=tmp[i].second )
						{
							flag = 0;
							cout<<"<Error> found in Line "<<linenum<<": index of the lower bound greater than or equal to upperbound."<<endl;
						}		
					}
					
					for(int i=tmp.size()-1; i>=0 && flag; i--)
						e.type.push_back( pair<int, int>(tmp[i].first, tmp[i].second) );
					
					for(int i=0; i<$<num>2 && flag; i++)
					{
						map<string, entry>::iterator it = s[s.size()-1].find( input.back() );
						if( it!=s[s.size()-1].end() )
							cout<<"<Error> found in Line "<<linenum<<": same ID '"<<input.back()<<"' redeclared."<<endl;
						else
							s[s.size()-1].insert( pair<string, entry>(input.back(), e) );
						input.pop_back();
					}
				}
			| VAR id_list MK_COLON literal_const MK_SEMICOLON     /* const declaration */
				{
					struct entry e;
					e.kind = 5;
					e.level = s.size()-1;
					
					e.type.push_back( pair<int, int>(type_config( input.back() ), 0) );
					input.pop_back();
					e.attribute.push_back( input.back() );
					input.pop_back();
					
					for(int i=0; i<$<num>2; i++)
					{
						map<string, entry>::iterator it = s[s.size()-1].find( input.back() );
						if( it!=s[s.size()-1].end() )
							cout<<"<Error> found in Line "<<linenum<<": same ID '"<<input.back()<<"' redeclaration."<<endl;
						else
							s[s.size()-1].insert( pair<string, entry>(input.back(), e) );
						input.pop_back();
					}
				}
			;
			
int_const	:	INT_CONST
			|	OCTAL_CONST
			;

literal_const	: int_const 	{ input.push_back(trust_str); input.push_back("INTEGER"); }
			| OP_SUB int_const 	{ string tmp = trust_str; input.push_back( "-" + tmp ); input.push_back("INTEGER"); }
			| FLOAT_CONST 		{ input.push_back(trust_str); input.push_back("REAL"); }
			| OP_SUB FLOAT_CONST{ string tmp = trust_str; input.push_back( "-" + tmp ); input.push_back("REAL"); }
			| SCIENTIFIC 		{ input.push_back(trust_str); input.push_back("REAL"); }
			| OP_SUB SCIENTIFIC { string tmp = trust_str; input.push_back( "-" + tmp ); input.push_back("REAL"); }
			| STR_CONST 		{ input.push_back(trust_str); input.push_back("STRING");}
			| TRUE 				{ input.push_back(trust_str); input.push_back("BOOLEAN"); }
			| FALSE 			{ input.push_back(trust_str); input.push_back("BOOLEAN"); }
			;

opt_func_decl_list	: func_decl_list
			| /* epsilon */
			;

func_decl_list		: func_decl_list func_decl
			| func_decl
			;

func_decl	: ID { input.push_back(trust_str); s.push_back( map<string, entry>() ); } MK_LPAREN opt_param_list MK_RPAREN opt_type MK_SEMICOLON
				{
					struct entry e;
					e.kind = 2;
					e.level = s.size()-2;
					if( type_config(input.back())>0 )
					{
						if( input.size()>=4 && input[input.size()-4]=="ARRAY" )
						{
							input.pop_back();
							while( input.size()>=3 && input[input.size()-3]=="ARRAY" )
							{
								input.pop_back();
								input.pop_back();
								input.pop_back();
							}
							cout<<"<Error> found in Line "<<linenum<<": function can't return array."<<endl;
							e.type.push_back( pair<int, int>(5, 0) );
						}
						else
						{
							e.type.push_back( pair<int, int>(type_config(input.back()), 0) );
							input.pop_back();
						}
					}
					else
						e.type.push_back( pair<int, int>(0, 0) );
						
					for(map<string, entry>::iterator it=s[s.size()-1].begin(); it!=s[s.size()-1].end(); it++)
					{
						if( it->second.kind==3 )
						{
							e.attribute.push_back( return_type( it->second.type ) );
						}
					}
					s[s.size()-2].insert( pair<string, entry>(input.back(), e) );
					if( e.type[0].first>0 )
						input.push_back( return_type2(e.type[0].first) );
				}
				func_compound_stmt END ID
				{
					if( type_config(input.back())>0 )
						input.pop_back();
					if( input.back()!=trust_str )
						cout<<"<Error> found in Line "<<linenum<<": define different function name."<<endl;
					input.pop_back();
					
					dumpsymbol();
					s.pop_back();
				}
			;

opt_param_list	: param_list
			| /* epsilon */
			;

param_list	: param_list MK_SEMICOLON param
			| param 
			;

param		: id_list MK_COLON type
				{
					struct entry e;
					e.kind = 3;
					e.level = s.size()-1;
					
					if( input.size()>=4 && input[input.size()-4]=="ARRAY" )
					{
						bool flag = 1;
						e.type.push_back( pair<int, int>(5, type_config(input.back()) ) );
						input.pop_back();
						
						vector< pair<int, int> > tmp;
						while( input.size()>=3 && input[input.size()-3]=="ARRAY" )
						{	
							int from, to;
							to = stoi( input.back(), nullptr, 10);
							input.pop_back();
							from = stoi( input.back(), nullptr, 10);
							input.pop_back();						
							tmp.push_back( pair<int, int>(from, to) );
							input.pop_back();
						}
						
						for(int i=tmp.size()-1; i>=0; i--)
						{
							if( tmp[i].first>=tmp[i].second )
							{
								flag = 0;
								cout<<"<Error> found in Line "<<linenum<<": index of the lower bound greater than or equal to upperbound."<<endl;
							}		
						}
					
						for(int i=tmp.size()-1; i>=0 && flag; i--)
							e.type.push_back( pair<int, int>(tmp[i].first, tmp[i].second) );	
					}
					else
					{
						e.type.push_back( pair<int, int>(type_config( input.back() ), 0) );
						input.pop_back();
					}
					
					for(int i=0; i<$<num>1; i++)
					{
						map<string, entry>::iterator it = s[s.size()-1].find( input.back() );
						if( it!=s[s.size()-1].end() )
							cout<<"<Error> found in Line "<<linenum<<": same ID '"<<input.back()<<"' redeclared."<<endl;
						else
							s[s.size()-1].insert( pair<string, entry>(input.back(), e) );
						input.pop_back();
					}
				}
			;

id_list		: id_list MK_COMMA ID { input.push_back(trust_str); $<num>$ = $<num>1 + 1; } 
			| ID { input.push_back(trust_str); $<num>$ = 1; };
			;

opt_type	: MK_COLON type
			| /* epsilon */
			;

type		: scalar_type
			| array_type
			;

scalar_type	: INTEGER 	{ input.push_back("INTEGER"); }
			| REAL 		{ input.push_back("REAL"); } 
			| BOOLEAN 	{ input.push_back("BOOLEAN"); } 
			| STRING 	{ input.push_back("STRING"); }
			;

array_type	: ARRAY { input.push_back("ARRAY"); } int_const { input.push_back(trust_str); } TO int_const { input.push_back(trust_str); } OF type
			;

stmt		: compound_stmt
			| simple_stmt
			| cond_stmt
			| while_stmt
			| for_stmt
			| return_stmt
			| proc_call_stmt
			;

func_compound_stmt 	: BEG opt_decl_list opt_stmt_list END	
			;
			
compound_stmt	: BEG { s.push_back( map<string, entry>() ); } opt_decl_list opt_stmt_list END { dumpsymbol(); s.pop_back(); }
			;

opt_stmt_list	: stmt_list
			| /* epsilon */
			;

stmt_list	: stmt_list stmt
			| stmt
			;

simple_stmt	: var_ref OP_ASSIGN boolean_expr MK_SEMICOLON
				{
					bool find = 0;
					for(int i=s.size()-1; i>=0; i--)
					{
						map<string, entry>::iterator it = s[i].find( input.back() );
						if( it!=s[i].end() )
						{
							find = 1;
							switch( it->second.kind )
							{
								case 1:
									cout<<"<Error> found in Line "<<linenum<<": can't assign value to a program."<<endl;
								break;
								case 2:
									cout<<"<Error> found in Line "<<linenum<<": can't assign value to a function."<<endl;
								break;
								case 3:
								case 4:
								{
									if( it->second.type[0].first==5 )
									{
										if( $<num>1==it->second.type.size() )
										{
											if( it->second.type[0].second==$<num>3 )
												$<num>$ = $<num>3;
											else if( it->second.type[0].second==2 && $<num>3==1 )
												$<num>$ = $<num>3;
											else
												cout<<"<Error> found in Line "<<linenum<<": different type assignment."<<endl;
										}
										else
										{
											cout<<"<Error> found in Line "<<linenum<<": var_ref array without enough index."<<endl;
										}
									}
									else
									{
										if( $<num>1==1 )
										{
											if( it->second.type[0].first==$<num>3 )
												$<num>$ = $<num>3;
											else if( it->second.type[0].first==2 && $<num>3==1 )
												$<num>$ = $<num>3;
											else
												cout<<"<Error> found in Line "<<linenum<<": different type assignment."<<endl;
										}
										else
										{
											cout<<"<Error> found in Line "<<linenum<<": "<<input.back()<<" isn't array type."<<endl;
										}
									}
								}
								break;
								case 5:
									cout<<"<Error> found in Line "<<linenum<<": can't assign value to a constan."<<endl;
								break;
							}
							break;
						}
					}
					if( !find )
					{
						cout<<"<Error> found in Line "<<linenum<<": Not find this variable."<<endl;
						$<num>$ = 0;
					}
					input.pop_back();
				}
			| PRINT boolean_expr MK_SEMICOLON
				{
					if( $<num>2>=1 && $<num>2<=4 )
						;
					else if( $<num>2==0 )
						cout<<"<Error> found in Line "<<linenum<<": can't print void type."<<endl;
					else if( $<num>2==5 )
						cout<<"<Error> found in Line "<<linenum<<": can't print array type."<<endl;
					else
						cout<<"<Error> found in Line "<<linenum<<": can't print unknown type."<<endl;
				}
			| READ boolean_expr MK_SEMICOLON
				{
					if( $<num>2>=1 && $<num>2<=4 )
						;
					else if( $<num>2==0 )
						cout<<"<Error> found in Line "<<linenum<<": can't read void type."<<endl;
					else if( $<num>2==5 )
						cout<<"<Error> found in Line "<<linenum<<": can't read array type."<<endl;
					else
						cout<<"<Error> found in Line "<<linenum<<": can't read unknown type."<<endl;
				}
			;

proc_call_stmt	: ID { input.push_back(trust_str); } MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
			{
				vector<int> tmp;
				for(int i=0; i<$<num>4; i++)
				{
					tmp.push_back( param.back() );
					param.pop_back();
				}
				
				map<string, entry>::iterator it = s[0].find( input.back() );
				if( it!=s[0].end() )
				{
					bool flag = check_param(input.back(), it->second.attribute, tmp);
					if( flag )
						$<num>$ = it->second.type[0].first;
				}
				else
				{
					cout<<"<Error> found in Line "<<linenum<<": function not declared."<<endl;
				}
				input.pop_back();
			}
			;

cond_stmt	: IF boolean_expr THEN opt_stmt_list ELSE opt_stmt_list END IF
				{
					if( $<num>2!=3 )
						cout<<"<Error> found in Line "<<linenum<<": condition type isn't boolean."<<endl;
				}
			| IF boolean_expr THEN opt_stmt_list END IF
				{
					if( $<num>2!=3 )
						cout<<"<Error> found in Line "<<linenum<<": condition type isn't boolean."<<endl;
				}
			;

while_stmt	: WHILE boolean_expr DO opt_stmt_list END DO
				{
					if( $<num>2!=3 )
						cout<<"<Error> found in Line "<<linenum<<": condition type isn't boolean."<<endl;
				}
			;
			
for_stmt	: FOR ID { input.push_back(trust_str); s.push_back( map<string, entry>() ); } OP_ASSIGN int_const { input.push_back(trust_str); } TO int_const 
			{
				string tmp = trust_str;
				int to = stoi(tmp, nullptr, 10), from;
				tmp = input.back();
				input.pop_back();
				from = stoi(tmp, nullptr, 10);
				tmp = input.back();
				input.pop_back();
				
				struct entry e;
				e.kind = 5;
				e.level = s.size()-1;
				e.type.push_back( pair<int, int>(1, 0) );
				
				if( from<to )
				{
					s[s.size()-1].insert( pair<string, entry>(tmp, e) );
				}
				else
				{
					cout<<"<Error> found in Line "<<linenum<<": for loop index error."<<endl;
				}
			} 
			DO opt_stmt_list END DO
			{
				s.pop_back();
			}
			;

return_stmt	: RETURN boolean_expr MK_SEMICOLON
				{
					if( type_config(input.back()) )
					{
						if( type_config(input.back())!=$<num>2 )
						{
							if( type_config(input.back())!=2 || $<num>2!=1 )
								cout<<"<Error> found in Line "<<linenum<<": error return value."<<endl;
						}
						else
							$<num>$ = $<num>2;
					}
					else
					{
						if( $<num>2!=0 )
							cout<<"<Error> found in Line "<<linenum<<": this function has not return value."<<endl;
					}
				}
			;

opt_boolean_expr_list	: boolean_expr_list { $<num>$ = $<num>1; }
			| /* epsilon */ { $<num>$ = 0; }
			;

boolean_expr_list	: boolean_expr_list MK_COMMA boolean_expr { $<num>$ = $<num>1 + 1; param.push_back( $<num>3 ); }
			| boolean_expr { $<num>$ = 1; param.push_back( $<num>1 ); }
			;

boolean_expr	: boolean_expr OP_OR boolean_term
				{ 
					if( $<num>1==3 )
					{
						if( $<num>3==3 )
							$<num>$ = 3;
						else
							cout<<"<Error> found in Line "<<linenum<<": error right operand type for or operation."<<endl;
					}
					else if( $<num>3==3 )
					{
						cout<<"<Error> found in Line "<<linenum<<": error left operand type for or operation."<<endl;
					}
					else
						cout<<"<Error> found in Line "<<linenum<<": error letf and right operand type for or operation."<<endl;
				}
			| boolean_term { $<num>$ = $<num>1; }
			;

boolean_term	: boolean_term OP_AND boolean_factor
				{ 
					if( $<num>1==3 )
					{
						if( $<num>3==3 )
							$<num>$ = 3;
						else
							cout<<"<Error> found in Line "<<linenum<<": error right operand type for and operation."<<endl;
					}
					else if( $<num>3==3 )
					{
						cout<<"<Error> found in Line "<<linenum<<": error left operand type for and operation."<<endl;
					}
					else
						cout<<"<Error> found in Line "<<linenum<<": error letf and right operand type for and operation."<<endl;
				}
			| boolean_factor { $<num>$ = $<num>1; }
			;

boolean_factor	: OP_NOT boolean_factor 
				{ 
					if( $<num>2==3 )
						$<num>$ = 3;
					else
						cout<<"<Error> found in Line "<<linenum<<": error operand type for not operation."<<endl;
				}
			| relop_expr { $<num>$ = $<num>1; }
			;

relop_expr	: expr rel_op expr
			{
				if( $<num>1==1 || $<num>1==2 )
				{
					if( $<num>3!=1 && $<num>3!=2 )
						cout<<"<Error> found in Line "<<linenum<<": right operand between relation operation are not integer or real."<<endl;
				}
				else if( $<num>3==1 || $<num>3==2 )
					cout<<"<Error> found in Line "<<linenum<<": left operand between relation operation are not integer or real."<<endl;
				else
					cout<<"<Error> found in Line "<<linenum<<": error left and right operand type for relation operator."<<endl;
				
				$<num>$ = 3;
			}
			| expr { $<num>$ = $<num>1; }
			;

rel_op		: OP_LT
			| OP_LE
			| OP_EQ
			| OP_GE
			| OP_GT
			| OP_NE
			;

expr		: expr add_op term
			{
				switch( $<num>2 )
				{
					case 4:
						if( $<num>1==1 )
						{
							if( $<num>3==1 )
								$<num>$ = 1;
							else if( $<num>3==2 )
								$<num>$ = 2;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for plus operation."<<endl;
						}
						else if( $<num>1==2 )
						{
							if( $<num>3==1 || $<num>3==2 )
								$<num>$ = 2;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for plus operation."<<endl;
						}
						else if( $<num>1==4 )
						{
							if( $<num>3==4 )
								$<num>$ = 4;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for string concatenation."<<endl;
						}
						else if( $<num>3==4 )
						{
							cout<<"<Error> found in Line "<<linenum<<": error left operand type for string concatenation."<<endl;
						}
						else
							cout<<"<Error> found in Line "<<linenum<<": error left and right operand type for for plus operation."<<endl;
					break;
					case 5:
						if( $<num>1==1 )
						{
							if( $<num>3==1 )
								$<num>$ = 1;
							else if( $<num>3==2 )
								$<num>$ = 2;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for minus operation."<<endl;
						}
						else if( $<num>1==2 )
						{
							if( $<num>3==1 || $<num>3==2 )
								$<num>$ = 2;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for minus operation."<<endl;
						}
						else if( $<num>3==1 || $<num>3==2 )
						{
							cout<<"<Error> found in Line "<<linenum<<": error left operand type for minus operation."<<endl;
						}
						else
							cout<<"<Error> found in Line "<<linenum<<": error left ans right operand type for minus operation."<<endl;
					break;
				}
				
			}
			| term { $<num>$ = $<num>1; }
			;

add_op		: OP_ADD { $<num>$ = 4; }
			| OP_SUB { $<num>$ = 5; }
			;

term		: term mul_op factor
			{
				switch( $<num>2 )
				{
					case 1:
						if( $<num>1==1 )
						{
							if( $<num>3==1 )
								$<num>$ = 1;
							else if( $<num>3==2 )
								$<num>$ = 2;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for multiplication operation."<<endl;
						}
						else if( $<num>1==2 )
						{
							if( $<num>3==1 || $<num>3==2 )
								$<num>$ = 2;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for multiplication operation."<<endl;
						}
						else
							cout<<"<Error> found in Line "<<linenum<<": error left operand type for multiplication operation."<<endl;
					break;
					case 2:
						if( $<num>1==1 )
						{
							if( $<num>3==1 )
								$<num>$ = 1;
							else if( $<num>3==2 )
								$<num>$ = 2;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for divide operation."<<endl;
						}
						else if( $<num>1==2 )
						{
							if( $<num>3==1 || $<num>3==2 )
								$<num>$ = 2;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for divide operation."<<endl;
						}
						else
							cout<<"<Error> found in Line "<<linenum<<": error left operand type for divide operation."<<endl;
					break;
					case 3:
						if( $<num>1==1 )
						{
							if( $<num>3==1 ) 
								$<num>$ = 1;
							else
								cout<<"<Error> found in Line "<<linenum<<": error right operand type for mod operation."<<endl;
						}
						else if( $<num>3==1 )
							cout<<"<Error> found in Line "<<linenum<<": error left operand type for mod operation."<<endl;
						else
							cout<<"<Error> found in Line "<<linenum<<": error left ans right operand type for mod operation."<<endl;
					break;
				}
				
			}
			| factor { $<num>$ = $<num>1; }
			;

mul_op		: OP_MUL { $<num>$ = 1; }
			| OP_DIV { $<num>$ = 2; }
			| OP_MOD { $<num>$ = 3; }
			;
			
factor		: var_ref 
				{
					bool find = 0;
					for(int i=s.size()-1; i>=0; i--)
					{
						map<string, entry>::iterator it = s[i].find( input.back() );
						if( it!=s[i].end() )
						{
							find = 1;
							if( it->second.type[0].first==5 )
							{
								if( $<num>1==1 )
								{
									cout<<"<Error> found in Line "<<linenum<<": array type without index."<<endl;
									$<num>$ = 5;
								}
								else
								{
									if( $<num>1==it->second.type.size() )
									{
										$<num>$ = it->second.type[0].second;
									}
									else
									{
										cout<<"<Error> found in Line "<<linenum<<": array type without enough index."<<endl;
										$<num>$ = 5;
									}
								}
							}
							else
							{
								if( $<num>1==1 )
									$<num>$ = it->second.type[0].first;	
								else
								{
									cout<<"<Error> found in Line "<<linenum<<": "<<input.back()<<" isn't array type."<<endl;
									$<num>$ = 5;
								}
							}
							break;
						}
					}
					if( !find )
					{
						cout<<"<Error> found in Line "<<linenum<<": Not find this variable."<<endl;
						$<num>$ = 0;
					}
					input.pop_back();
				}
			| OP_SUB var_ref
				{
					bool find = 0;
					for(int i=s.size()-1; i>=0; i--)
					{
						map<string, entry>::iterator it = s[i].find( input.back() );
						if( it!=s[i].end() )
						{
							find = 1;
							if( it->second.type[0].first==5 )
							{
								if( $<num>1==1 )
								{
									cout<<"<Error> found in Line "<<linenum<<": array type without index."<<endl;
									$<num>$ = 5;
								}
								else
								{
									if( $<num>1==it->second.type.size() )
									{
										if( it->second.type[0].second==1 || it->second.type[0].second==2 )
											$<num>$ = it->second.type[0].second;
										else
											cout<<"<Error> found in Line "<<linenum<<": only integer and real can be negative."<<endl;
									}
									else
									{
										cout<<"<Error> found in Line "<<linenum<<": array type without enough index."<<endl;
										$<num>$ = 5;
									}
								}
							}
							else
							{
								if( $<num>1==1 )
								{
									if( it->second.type[0].first==1 || it->second.type[0].first==2 )
										$<num>$ = it->second.type[0].first;	
									else
										cout<<"<Error> found in Line "<<linenum<<": only integer and real can be negative."<<endl;
								}
								else
								{
									cout<<"<Error> found in Line "<<linenum<<": "<<input.back()<<" isn't array type."<<endl;
									$<num>$ = 5;
								}
							}
							break;
						}
					}
					if( !find )
					{
						cout<<"<Error> found in Line "<<linenum<<": Not find this variable."<<endl;
						$<num>$ = 0;
					}
					input.pop_back();
				}
			| MK_LPAREN boolean_expr MK_RPAREN
				{
					$<num>$ = $<num>2;
				}
			| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
				{
					if( $<num>3==1 || $<num>3==2 )
						$<num>$ = $<num>3;
					else
						cout<<"<Error> found in Line "<<linenum<<": only integer and real can be negative."<<endl;
				}
			| ID { input.push_back(trust_str); } MK_LPAREN opt_boolean_expr_list MK_RPAREN
				{
					vector<int> tmp;
					for(int i=0; i<$<num>4; i++)
					{
						tmp.push_back( param.back() );
						param.pop_back();
					}
					
					map<string, entry>::iterator it = s[0].find( input.back() );
					if( it!=s[0].end() )
					{
						bool flag = check_param(input.back(), it->second.attribute, tmp);
						if( flag )
							$<num>$ = it->second.type[0].first;
					}
					else
					{
						cout<<"<Error> found in Line "<<linenum<<": function not declared."<<endl;
					}
					input.pop_back();
				}
			| OP_SUB ID { input.push_back(trust_str); } MK_LPAREN opt_boolean_expr_list MK_RPAREN
				{
					vector<int> tmp;
					for(int i=0; i<$<num>5; i++)
					{
						tmp.push_back( param.back() );
						param.pop_back();
					}
					
					map<string, entry>::iterator it = s[0].find( input.back() );
					if( it!=s[0].end() )
					{
						bool flag = check_param(input.back(), it->second.attribute, tmp);
						if( flag )
						{
							if( it->second.type[0].first==1 || it->second.type[0].first==2 )
								$<num>$ = it->second.type[0].first;
							else
								cout<<"<Error> found in Line "<<linenum<<": only integer and real can be negative."<<endl;
						}	
					}
					else
					{
						cout<<"<Error> found in Line "<<linenum<<": function not declared."<<endl;
					}
					input.pop_back();
				}
			| literal_const
				{
					$<num>$ = type_config( input.back() );
					input.pop_back();
					input.pop_back();
				}
			;

var_ref		: ID { input.push_back(trust_str); $<num>$ = 1; }
			| var_ref dim { $<num>$ = $<num>1 + 1; }
			;

dim			: MK_LB boolean_expr MK_RB
				{
					if( $<num>2!=1 )
						cout<<"<Error> found in Line "<<linenum<<": index of array isn't integer."<<endl;
				}
			;

%%


int  main( int argc, char **argv )
{
	if( argc != 2 ) {
		fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
		exit(0);
	}

	FILE *fp = fopen( argv[1], "r" );
	input_file = argv[1];
	
	if( fp == NULL )  {
		fprintf( stdout, "Open  file  error\n" );
		exit(-1);
	}
	
	yyin = fp;
	yyparse();	/* primary procedure of parser */
	
	fprintf( stdout, "\n|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	
	exit(0);
}
