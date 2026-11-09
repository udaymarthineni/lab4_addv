#define FIFO_SIZE 16

//FIFO state 
int fifo_data[FIFO_SIZE];
int write_ptr = 0;
int read_ptr = 0;
int count = 0;

// Reset old data 
void fifo_init(void)
{
    write_ptr = 0;
    read_ptr = 0;
    count = 0;
}

int fifo_push(int data)
{
    if (count == FIFO_SIZE)
        return 0;
    fifo_data[write_ptr] = data;
    write_ptr = (write_ptr + 1) % FIFO_SIZE;
    count++;
    return 1;
}

int fifo_pop(void)
{
    int data;
    if (count == 0)
        return -1;

    data = fifo_data[read_ptr];
    read_ptr = (read_ptr + 1) % FIFO_SIZE;
    count--;
    return data;
}

int fifo_is_empty(void)
{
    return count == 0;
}

int fifo_is_full(void)
{
    return count == FIFO_SIZE;
}

int fifo_get_count(void)
{
    return count;
}
// Read lst word not zero.
int fifo_peek(void)
{
    if (count == 0)
        return -1;
    return fifo_data[read_ptr];
}

int fifo_is_almost_full(void)
{
    return count == 12;
}

int fifo_is_almost_empty(void)
{
    return count == 4;
}
