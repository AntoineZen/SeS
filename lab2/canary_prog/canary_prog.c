


void bad_function()
{
    int i;
    // Decalre an array of 16 int on the stack.
    int some_array[16];

    // Overflow the array on the stack

    for(i=0; i < 24; i++)
    {
        some_array[i] = i;
    }   
}

void good_function()
{
    int i;
    // Decalre an array of 16 int on the stack.
    int some_array[16];

    // Overflow the array on the stack

    for(i=0; i < 16; i++)
    {
        some_array[i] = i;
    }   
}

int main()
{
    good_function();
    bad_function();
    return 0;
}
