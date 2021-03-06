﻿module cl4d.kernel;

import cl4d.c.cl;
import cl4d.buffer;
import cl4d.program;
import cl4d.taskmanager;

import std.string;
import std.typecons;
import std.array;
import std.algorithm;


///カーネルを表すためのクラスです
class Kernel{
private:
    Program _program;
    cl_kernel _kernel;

public:
    ///コンストラクタ
    this(Program program, string name){
        _program = program;
        cl_errcode err;
        _kernel = clCreateKernel(  program.clProgram,
                                            toStringz(name),
                                            &err);
        
        assert(err == CL_SUCCESS);
    }
    
    
    ~this(){
        clReleaseKernel(_kernel);
    }
    
    
    ///内部で保持している値を返します
    @property
    cl_kernel clKernel(){
        return _kernel;
    }
    
    /+
    ///Kernelに実行時のスレッド数と引数とセットし、実行するようにコマンドキューに入れ込みます。
    Event set(SizeT, T...)(Tuple!(SizeT, SizeT)[] dims, T args)if(is(SizeT : size_t)){
        cl_errcode err;
        foreach(idx, U; T){
            static if(isArray!U){
                cl_mem buf = args[idx].buffer.clMem;
                err = clSetKernelArg(   _kernel,
                                        idx,
                                        size_t.sizeof,
                                        &buf);
            }else static if(is(U == Local)){
                err = clSetKernelArg(   _kernel,
                                        idx,
                                        args[idx].size,
                                        null);
            }else{
                auto tmp = args[idx];
                err = clSetKernelArg(   _kernel,
                                        idx,
                                        U.sizeof,
                                        &tmp);
            }
            
            //import std.stdio;
            //writeln(err);
            assert(err == CL_SUCCESS);
        }
        
        size_t[] global = array(map!"a[0]"(dims));
        size_t[] local =  array(map!"a[1]"(dims));
        
        return _program.device.taskManager.addTask({
            cl_event event;
            err = clEnqueueNDRangeKernel(   _program.device.taskManager.clCommandQueue,
                                            _kernel,
                                            dims.length,
                                            null,
                                            global.ptr,
                                            local.ptr,
                                            0,
                                            null,
                                            &event);
            args = typeof(args).init;
            assert(err == CL_SUCCESS);
            return event;
        });
    }+/
    
    Kernel setParameter(size_t offset = 0, T...)(T args)
    {
        static if(T.length == 0)
            return this;
        else{
            
            cl_errcode err;
            alias T[0] U;
            
            static if(cl4d.buffer.isArray!U){
                cl_mem buf = args[0].buffer.clMem;
                err = clSetKernelArg(   _kernel,
                                        offset,
                                        size_t.sizeof,
                                        &buf);
            }else static if(is(U == Local)){
                err = clSetKernelArg(   _kernel,
                                        offset,
                                        args[0].size,
                                        null);
            }else{
                auto tmp = args[0];
                err = clSetKernelArg(   _kernel,
                                        offset,
                                        U.sizeof,
                                        &tmp);
            }
             assert(err == CL_SUCCESS);
            
            return setParameter!(offset + 1)(args[1..$]);
        }
    }
    
    
    Event opCall(Tuple!(size_t, size_t)[] dims...)
    in{
        assert(dims.length <= 3);
    }
    body{
        size_t[] global = array(map!"a[0]"(dims));
        size_t[] local =  array(map!"a[1]"(dims));
        
        return _program.device.taskManager.addTask({
            cl_event event;
            cl_errcode err;
            err = clEnqueueNDRangeKernel(   _program.device.taskManager.clCommandQueue,
                                            _kernel,
                                            dims.length,
                                            null,
                                            global.ptr,
                                            local.ptr,
                                            0,
                                            null,
                                            &event);
            assert(err == CL_SUCCESS);
            return event;
        });
    }
    
}

private struct Local{}

void clEnqueueNDRangeKernelException(cl_errcode err){
    assert(err == CL_SUCCESS);
}