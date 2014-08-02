#include <iostream>
using std::cout;
using std::endl;
using std::cin;


#include "math/add.h"
#include "math/multiply.h"

int main(){
	cout<<"please enter two integer:"<<endl;

	int a,b;
	cin>>a>>b;

	cout<<"add("<<a<<","<<b<<") returns "<<add(a,b)<<endl;
	cout<<"multiply("<<a<<","<<b<<") returns "<<multiply(a,b)<<endl;

	int hello_world();
	hello_world();
}
