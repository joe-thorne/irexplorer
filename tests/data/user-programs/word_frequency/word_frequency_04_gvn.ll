; ModuleID = '/workspace/out/word_frequency_03_simplifycfg.ll'
source_filename = "/workspace/user-programs/word_frequency.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct.table = type { [256 x %struct.entry], i32 }
%struct.entry = type { [24 x i8], i32, i32 }

@main.table = internal global %struct.table zeroinitializer, align 4, !dbg !0
@main.entries = internal global [256 x %struct.entry] zeroinitializer, align 16, !dbg !37
@passage = internal global ptr @.str.4, align 8, !dbg !72
@.str = private unnamed_addr constant [4 x i8] c"fox\00", align 1, !dbg !50
@.str.1 = private unnamed_addr constant [4 x i8] c"cat\00", align 1, !dbg !55
@.str.2 = private unnamed_addr constant [18 x i8] c"fox: %d, cat: %d\0A\00", align 1, !dbg !57
@stderr = external global ptr, align 8
@.str.3 = private unnamed_addr constant [23 x i8] c"table full at word %d\0A\00", align 1, !dbg !62
@.str.4 = private unnamed_addr constant [285 x i8] c"The quick brown fox jumps over the lazy dog. The dog sleeps, and the fox runs into the forest. In the forest the fox finds a river; the river is cold and the fox is quick. A lazy dog never finds the river, but the quick fox always does. Over the hills and over the river the fox runs.\00", align 1, !dbg !67
@.str.5 = private unnamed_addr constant [23 x i8] c"%d words, %d distinct\0A\00", align 1, !dbg !76
@.str.6 = private unnamed_addr constant [11 x i8] c"%-10s %3d \00", align 1, !dbg !78
@.str.7 = private unnamed_addr constant [18 x i8] c"longest word: %s\0A\00", align 1, !dbg !83
@.str.8 = private unnamed_addr constant [27 x i8] c"mean length: %.2f letters\0A\00", align 1, !dbg !85
@.str.9 = private unnamed_addr constant [21 x i8] c"words seen once: %d\0A\00", align 1, !dbg !90

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !2 {
entry:
  call void @table_init(ptr noundef nonnull @main.table), !dbg !108
  %0 = load ptr, ptr @passage, align 8, !dbg !109
  %call = call i32 @count_words(ptr noundef nonnull @main.table, ptr noundef %0), !dbg !110
    #dbg_value(i32 %call, !111, !DIExpression(), !112)
  %call1 = call i32 @collect(ptr noundef nonnull @main.table, ptr noundef nonnull @main.entries), !dbg !113
    #dbg_value(i32 %call1, !114, !DIExpression(), !112)
  call void @report(ptr noundef nonnull @main.entries, i32 noundef %call1, i32 noundef %call), !dbg !115
  %call2 = call i32 @table_lookup(ptr noundef nonnull @main.table, ptr noundef nonnull @.str), !dbg !116
    #dbg_value(i32 %call2, !117, !DIExpression(), !112)
  %call3 = call i32 @table_lookup(ptr noundef nonnull @main.table, ptr noundef nonnull @.str.1), !dbg !118
    #dbg_value(i32 %call3, !119, !DIExpression(), !112)
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef %call2, i32 noundef %call3) #7, !dbg !120
  %cmp = icmp sgt i32 %call2, 0, !dbg !121
  %cmp5 = icmp ne i32 %call3, 0, !dbg !122
  %1 = zext i1 %cmp5 to i32, !dbg !122
  %not. = select i1 %cmp, i32 %1, i32 1, !dbg !122
  ret i32 %not., !dbg !123
}

; Function Attrs: noinline nounwind uwtable
define internal void @table_init(ptr noundef %table) #0 !dbg !124 {
entry:
    #dbg_value(ptr %table, !128, !DIExpression(), !129)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(8196) %table, i8 0, i64 8196, i1 false), !dbg !130
  ret void, !dbg !131
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @count_words(ptr noundef %table, ptr noundef %text) #0 !dbg !132 {
entry:
  %text.addr = alloca ptr, align 8
  %word = alloca [24 x i8], align 16
    #dbg_value(ptr %table, !135, !DIExpression(), !136)
    #dbg_value(ptr %text, !137, !DIExpression(), !136)
  store ptr %text, ptr %text.addr, align 8
    #dbg_declare(ptr %word, !138, !DIExpression(), !139)
    #dbg_value(i32 0, !140, !DIExpression(), !136)
  br label %while.cond, !dbg !141

while.cond:                                       ; preds = %if.end, %entry
  %position.0 = phi i32 [ 0, %entry ], [ %inc, %if.end ], !dbg !136
    #dbg_value(i32 %position.0, !140, !DIExpression(), !136)
    #dbg_value(ptr %text.addr, !137, !DIExpression(DW_OP_deref), !136)
  %call = call i32 @next_word(ptr noundef nonnull %text.addr, ptr noundef nonnull %word), !dbg !142
  %cmp = icmp sgt i32 %call, 0, !dbg !143
  br i1 %cmp, label %while.body, label %while.end, !dbg !141

while.body:                                       ; preds = %while.cond
  %call2 = call i32 @table_add(ptr noundef %table, ptr noundef nonnull %word, i32 noundef %position.0), !dbg !144
  %cmp3 = icmp slt i32 %call2, 0, !dbg !147
  br i1 %cmp3, label %if.then, label %if.end, !dbg !147

if.then:                                          ; preds = %while.body
  %0 = load ptr, ptr @stderr, align 8, !dbg !148
  %call4 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str.3, i32 noundef %position.0) #8, !dbg !150
  br label %while.end, !dbg !151

if.end:                                           ; preds = %while.body
  %inc = add nuw nsw i32 %position.0, 1, !dbg !152
    #dbg_value(i32 %inc, !140, !DIExpression(), !136)
  br label %while.cond, !dbg !141, !llvm.loop !153

while.end:                                        ; preds = %if.then, %while.cond
  ret i32 %position.0, !dbg !156
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @collect(ptr noundef %table, ptr noundef %out) #0 !dbg !157 {
entry:
    #dbg_value(ptr %table, !163, !DIExpression(), !164)
    #dbg_value(ptr %out, !165, !DIExpression(), !164)
    #dbg_value(i32 0, !166, !DIExpression(), !164)
    #dbg_value(i32 0, !167, !DIExpression(), !169)
  br label %for.cond, !dbg !170

for.cond:                                         ; preds = %for.inc, %entry
  %n.0 = phi i32 [ 0, %entry ], [ %n.1, %for.inc ], !dbg !164
  %i.0 = phi i32 [ 0, %entry ], [ %inc7, %for.inc ], !dbg !171
    #dbg_value(i32 %i.0, !167, !DIExpression(), !169)
    #dbg_value(i32 %n.0, !166, !DIExpression(), !164)
  %cmp = icmp samesign ult i32 %i.0, 256, !dbg !172
  br i1 %cmp, label %for.body, label %for.end, !dbg !174

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !175
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !175
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !178
  %0 = load i32, ptr %count, align 4, !dbg !178
  %cmp1 = icmp sgt i32 %0, 0, !dbg !179
  br i1 %cmp1, label %if.then, label %for.inc, !dbg !179

if.then:                                          ; preds = %for.body
  %inc = add nsw i32 %n.0, 1, !dbg !180
    #dbg_value(i32 %inc, !166, !DIExpression(), !164)
  %idxprom2 = sext i32 %n.0 to i64, !dbg !182
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %out, i64 %idxprom2, !dbg !182
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(32) %arrayidx3, ptr noundef nonnull align 4 dereferenceable(32) %arrayidx, i64 32, i1 false), !dbg !183
  br label %for.inc, !dbg !184

for.inc:                                          ; preds = %if.then, %for.body
  %n.1 = phi i32 [ %inc, %if.then ], [ %n.0, %for.body ], !dbg !164
    #dbg_value(i32 %n.1, !166, !DIExpression(), !164)
  %inc7 = add nuw nsw i32 %i.0, 1, !dbg !185
    #dbg_value(i32 %inc7, !167, !DIExpression(), !169)
  br label %for.cond, !dbg !186, !llvm.loop !187

for.end:                                          ; preds = %for.cond
  %conv = sext i32 %n.0 to i64, !dbg !189
  call void @qsort(ptr noundef %out, i64 noundef %conv, i64 noundef 32, ptr noundef nonnull @by_count) #7, !dbg !190
  ret i32 %n.0, !dbg !191
}

; Function Attrs: noinline nounwind uwtable
define internal void @report(ptr noundef %entries, i32 noundef %n, i32 noundef %total) #0 !dbg !192 {
entry:
    #dbg_value(ptr %entries, !197, !DIExpression(), !198)
    #dbg_value(i32 %n, !199, !DIExpression(), !198)
    #dbg_value(i32 %total, !200, !DIExpression(), !198)
  %cmp = icmp slt i32 %n, 8, !dbg !201
  %n. = select i1 %cmp, i32 %n, i32 8, !dbg !202
    #dbg_value(i32 %n., !203, !DIExpression(), !198)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.5, i32 noundef %total, i32 noundef %n) #7, !dbg !204
    #dbg_value(i32 0, !205, !DIExpression(), !207)
  br label %for.cond, !dbg !208

for.cond:                                         ; preds = %for.body, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ], !dbg !209
    #dbg_value(i32 %i.0, !205, !DIExpression(), !207)
  %cmp1 = icmp slt i32 %i.0, %n., !dbg !210
  br i1 %cmp1, label %for.body, label %for.end, !dbg !212

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !213
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !213
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !215
  %0 = load i32, ptr %count, align 4, !dbg !215
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.6, ptr noundef %arrayidx, i32 noundef %0) #7, !dbg !216
  %1 = load i32, ptr %count, align 4, !dbg !217
  %count9 = getelementptr inbounds nuw i8, ptr %entries, i64 24, !dbg !218
  %2 = load i32, ptr %count9, align 4, !dbg !218
  call void @print_bar(i32 noundef %1, i32 noundef %2), !dbg !219
  %inc = add nuw nsw i32 %i.0, 1, !dbg !220
    #dbg_value(i32 %inc, !205, !DIExpression(), !207)
  br label %for.cond, !dbg !221, !llvm.loop !222

for.end:                                          ; preds = %for.cond
  %call11 = call ptr @longest(ptr noundef %entries, i32 noundef %n), !dbg !224
    #dbg_value(ptr %call11, !225, !DIExpression(), !198)
  %cmp12.not = icmp eq ptr %call11, null, !dbg !226
  br i1 %cmp12.not, label %if.end, label %if.then, !dbg !226

if.then:                                          ; preds = %for.end
  %call15 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.7, ptr noundef nonnull %call11) #7, !dbg !228
  br label %if.end, !dbg !230

if.end:                                           ; preds = %if.then, %for.end
  %call16 = call double @mean_length(ptr noundef %entries, i32 noundef %n), !dbg !231
  %call17 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.8, double noundef %call16) #7, !dbg !232
  %call18 = call i32 @singletons(ptr noundef %entries, i32 noundef %n), !dbg !233
  %call19 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.9, i32 noundef %call18) #7, !dbg !234
  ret void, !dbg !235
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_lookup(ptr noundef %table, ptr noundef %word) #0 !dbg !236 {
entry:
    #dbg_value(ptr %table, !239, !DIExpression(), !240)
    #dbg_value(ptr %word, !241, !DIExpression(), !240)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !242
    #dbg_value(i32 %call, !243, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !240)
    #dbg_value(i32 0, !244, !DIExpression(), !246)
  br label %for.cond, !dbg !247

for.cond:                                         ; preds = %for.inc, %entry
  %index.0.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !248
  %index.0 = and i32 %index.0.in, 255, !dbg !240
    #dbg_value(i32 %probe.0, !244, !DIExpression(), !246)
    #dbg_value(i32 %index.0, !243, !DIExpression(), !240)
  %cmp = icmp samesign ult i32 %probe.0, 256, !dbg !249
  br i1 %cmp, label %for.body, label %return, !dbg !251

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %index.0 to i64, !dbg !252
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !252
    #dbg_value(ptr %arrayidx, !254, !DIExpression(), !255)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !256
  %0 = load i32, ptr %count, align 4, !dbg !256
  %cmp1 = icmp eq i32 %0, 0, !dbg !258
  br i1 %cmp1, label %return, label %if.end, !dbg !258

if.end:                                           ; preds = %for.body
  %call3 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #9, !dbg !259
  %cmp4 = icmp eq i32 %call3, 0, !dbg !261
  br i1 %cmp4, label %if.then5, label %for.inc, !dbg !261

if.then5:                                         ; preds = %if.end
  br label %return, !dbg !262

for.inc:                                          ; preds = %if.end
    #dbg_value(i32 poison, !243, !DIExpression(), !240)
  %add = add nuw nsw i32 %index.0, 1, !dbg !264
    #dbg_value(i32 %add, !243, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !240)
  %inc = add nuw nsw i32 %probe.0, 1, !dbg !265
    #dbg_value(i32 %inc, !244, !DIExpression(), !246)
  br label %for.cond, !dbg !266, !llvm.loop !267

return:                                           ; preds = %if.then5, %for.body, %for.cond
  %retval.0 = phi i32 [ 0, %for.body ], [ %0, %if.then5 ], [ 0, %for.cond ], !dbg !240
  ret i32 %retval.0, !dbg !269
}

declare i32 @printf(ptr noundef, ...) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: noinline nounwind uwtable
define internal i32 @next_word(ptr noundef %text, ptr noundef %word) #0 !dbg !270 {
entry:
    #dbg_value(ptr %text, !275, !DIExpression(), !276)
    #dbg_value(ptr %word, !277, !DIExpression(), !276)
  %0 = load ptr, ptr %text, align 8, !dbg !278
    #dbg_value(ptr %0, !279, !DIExpression(), !276)
  br label %while.cond, !dbg !280

while.cond:                                       ; preds = %while.body, %entry
  %p.0 = phi ptr [ %0, %entry ], [ %incdec.ptr, %while.body ], !dbg !276
    #dbg_value(ptr %p.0, !279, !DIExpression(), !276)
  %1 = load i8, ptr %p.0, align 1, !dbg !281
  %cmp.not = icmp eq i8 %1, 0, !dbg !282
  br i1 %cmp.not, label %while.end, label %land.rhs, !dbg !283

land.rhs:                                         ; preds = %while.cond
  %call = call ptr @__ctype_b_loc() #10, !dbg !284
  %2 = load ptr, ptr %call, align 8, !dbg !284
  %idxprom = zext i8 %1 to i64, !dbg !284
  %arrayidx = getelementptr inbounds nuw i16, ptr %2, i64 %idxprom, !dbg !284
  %3 = load i16, ptr %arrayidx, align 2, !dbg !284
  %4 = and i16 %3, 1024, !dbg !284
  %tobool.not = icmp eq i16 %4, 0, !dbg !285
  br i1 %tobool.not, label %while.body, label %while.end, !dbg !280

while.body:                                       ; preds = %land.rhs
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !286
    #dbg_value(ptr %incdec.ptr, !279, !DIExpression(), !276)
  br label %while.cond, !dbg !280, !llvm.loop !288

while.end:                                        ; preds = %land.rhs, %while.cond
    #dbg_value(i32 0, !290, !DIExpression(), !276)
  br label %while.cond4, !dbg !291

while.cond4:                                      ; preds = %if.end, %while.end
  %5 = phi i8 [ %1, %while.end ], [ %.pre, %if.end ], !dbg !292
  %p.1 = phi ptr [ %p.0, %while.end ], [ %incdec.ptr20, %if.end ], !dbg !276
  %length.0 = phi i32 [ 0, %while.end ], [ %length.1, %if.end ], !dbg !276
    #dbg_value(i32 %length.0, !290, !DIExpression(), !276)
    #dbg_value(ptr %p.1, !279, !DIExpression(), !276)
  %call5 = call ptr @__ctype_b_loc() #10, !dbg !293
  %6 = load ptr, ptr %call5, align 8, !dbg !293
  %idxprom7 = zext i8 %5 to i64, !dbg !293
  %arrayidx8 = getelementptr inbounds nuw i16, ptr %6, i64 %idxprom7, !dbg !293
  %7 = load i16, ptr %arrayidx8, align 2, !dbg !293
  %8 = and i16 %7, 1024, !dbg !293
  %tobool11.not = icmp eq i16 %8, 0, !dbg !291
  br i1 %tobool11.not, label %while.end21, label %while.body12, !dbg !291

while.body12:                                     ; preds = %while.cond4
  %cmp13 = icmp slt i32 %length.0, 23, !dbg !294
  br i1 %cmp13, label %if.then, label %if.end, !dbg !294

if.then:                                          ; preds = %while.body12
  %conv15 = zext i8 %5 to i32, !dbg !297
  %call16 = call i32 @tolower(i32 noundef %conv15) #9, !dbg !299
  %conv17 = trunc i32 %call16 to i8, !dbg !300
  %inc = add nsw i32 %length.0, 1, !dbg !301
    #dbg_value(i32 %inc, !290, !DIExpression(), !276)
  %idxprom18 = sext i32 %length.0 to i64, !dbg !302
  %arrayidx19 = getelementptr inbounds i8, ptr %word, i64 %idxprom18, !dbg !302
  store i8 %conv17, ptr %arrayidx19, align 1, !dbg !303
  br label %if.end, !dbg !304

if.end:                                           ; preds = %if.then, %while.body12
  %length.1 = phi i32 [ %inc, %if.then ], [ %length.0, %while.body12 ], !dbg !276
    #dbg_value(i32 %length.1, !290, !DIExpression(), !276)
  %incdec.ptr20 = getelementptr inbounds nuw i8, ptr %p.1, i64 1, !dbg !305
    #dbg_value(ptr %incdec.ptr20, !279, !DIExpression(), !276)
  %.pre = load i8, ptr %incdec.ptr20, align 1, !dbg !292
  br label %while.cond4, !dbg !291, !llvm.loop !306

while.end21:                                      ; preds = %while.cond4
  %idxprom22 = sext i32 %length.0 to i64, !dbg !308
  %arrayidx23 = getelementptr inbounds i8, ptr %word, i64 %idxprom22, !dbg !308
  store i8 0, ptr %arrayidx23, align 1, !dbg !309
  store ptr %p.1, ptr %text, align 8, !dbg !310
  ret i32 %length.0, !dbg !311
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_add(ptr noundef %table, ptr noundef %word, i32 noundef %position) #0 !dbg !312 {
entry:
    #dbg_value(ptr %table, !315, !DIExpression(), !316)
    #dbg_value(ptr %word, !317, !DIExpression(), !316)
    #dbg_value(i32 %position, !318, !DIExpression(), !316)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !319
    #dbg_value(i32 %call, !320, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !316)
    #dbg_value(i32 0, !321, !DIExpression(), !323)
  br label %for.cond, !dbg !324

for.cond:                                         ; preds = %for.inc, %entry
  %index.0.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.0 = phi i32 [ 0, %entry ], [ %inc14, %for.inc ], !dbg !325
  %index.0 = and i32 %index.0.in, 255, !dbg !316
    #dbg_value(i32 %probe.0, !321, !DIExpression(), !323)
    #dbg_value(i32 %index.0, !320, !DIExpression(), !316)
  %cmp = icmp samesign ult i32 %probe.0, 256, !dbg !326
  br i1 %cmp, label %for.body, label %return, !dbg !328

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %index.0 to i64, !dbg !329
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !329
    #dbg_value(ptr %arrayidx, !331, !DIExpression(), !332)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !333
  %0 = load i32, ptr %count, align 4, !dbg !333
  %cmp1 = icmp eq i32 %0, 0, !dbg !335
  br i1 %cmp1, label %if.then, label %if.end, !dbg !335

if.then:                                          ; preds = %for.body
  %call3 = call ptr @strncpy(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word, i64 noundef 23) #7, !dbg !336
  store i32 1, ptr %count, align 4, !dbg !338
  %first_seen = getelementptr inbounds nuw i8, ptr %arrayidx, i64 28, !dbg !339
  store i32 %position, ptr %first_seen, align 4, !dbg !340
  %used = getelementptr inbounds nuw i8, ptr %table, i64 8192, !dbg !341
  %1 = load i32, ptr %used, align 4, !dbg !342
  %inc = add nsw i32 %1, 1, !dbg !342
  store i32 %inc, ptr %used, align 4, !dbg !342
  br label %return, !dbg !343

if.end:                                           ; preds = %for.body
  %call7 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #9, !dbg !344
  %cmp8 = icmp eq i32 %call7, 0, !dbg !346
  br i1 %cmp8, label %if.then9, label %for.inc, !dbg !346

if.then9:                                         ; preds = %if.end
  %inc11 = add nsw i32 %0, 1, !dbg !347
  store i32 %inc11, ptr %count, align 4, !dbg !347
  br label %return, !dbg !349

for.inc:                                          ; preds = %if.end
    #dbg_value(i32 poison, !320, !DIExpression(), !316)
  %add = add nuw nsw i32 %index.0, 1, !dbg !350
    #dbg_value(i32 %add, !320, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !316)
  %inc14 = add nuw nsw i32 %probe.0, 1, !dbg !351
    #dbg_value(i32 %inc14, !321, !DIExpression(), !323)
  br label %for.cond, !dbg !352, !llvm.loop !353

return:                                           ; preds = %if.then9, %if.then, %for.cond
  %retval.0 = phi i32 [ 1, %if.then ], [ 0, %if.then9 ], [ -1, %for.cond ], !dbg !316
  ret i32 %retval.0, !dbg !355
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #3

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #4

; Function Attrs: nounwind willreturn memory(read)
declare i32 @tolower(i32 noundef) #5

; Function Attrs: noinline nounwind uwtable
define internal i32 @hash_word(ptr noundef %word) #0 !dbg !356 {
entry:
    #dbg_value(ptr %word, !359, !DIExpression(), !360)
    #dbg_value(i32 -2128831035, !361, !DIExpression(), !360)
    #dbg_value(ptr %word, !362, !DIExpression(), !364)
  br label %for.cond, !dbg !365

for.cond:                                         ; preds = %for.inc, %entry
  %hash.0 = phi i32 [ -2128831035, %entry ], [ %mul, %for.inc ], !dbg !360
  %p.0 = phi ptr [ %word, %entry ], [ %incdec.ptr, %for.inc ], !dbg !366
    #dbg_value(ptr %p.0, !362, !DIExpression(), !364)
    #dbg_value(i32 %hash.0, !361, !DIExpression(), !360)
  %0 = load i8, ptr %p.0, align 1, !dbg !367
  %cmp.not = icmp eq i8 %0, 0, !dbg !369
  br i1 %cmp.not, label %for.end, label %for.inc, !dbg !370

for.inc:                                          ; preds = %for.cond
    #dbg_value(!DIArgList(i32 poison, i8 poison), !361, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_stack_value), !360)
    #dbg_value(!DIArgList(i32 poison, i8 poison), !361, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !360)
    #dbg_value(!DIArgList(i32 %hash.0, i8 %0), !361, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !360)
  %conv2 = zext i8 %0 to i32, !dbg !371
    #dbg_value(!DIArgList(i32 %hash.0, i32 %conv2), !361, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !360)
  %xor = xor i32 %hash.0, %conv2, !dbg !373
    #dbg_value(i32 %xor, !361, !DIExpression(DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !360)
  %mul = mul i32 %xor, 16777619, !dbg !374
    #dbg_value(i32 %mul, !361, !DIExpression(), !360)
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !375
    #dbg_value(ptr %incdec.ptr, !362, !DIExpression(), !364)
  br label %for.cond, !dbg !376, !llvm.loop !377

for.end:                                          ; preds = %for.cond
  ret i32 %hash.0, !dbg !379
}

; Function Attrs: nounwind
declare ptr @strncpy(ptr noundef, ptr noundef, i64 noundef) #3

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #6

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #1

; Function Attrs: noinline nounwind uwtable
define internal i32 @by_count(ptr noundef %a, ptr noundef %b) #0 !dbg !380 {
entry:
    #dbg_value(ptr %a, !385, !DIExpression(), !386)
    #dbg_value(ptr %b, !387, !DIExpression(), !386)
    #dbg_value(ptr %a, !388, !DIExpression(), !386)
    #dbg_value(ptr %b, !389, !DIExpression(), !386)
  %count = getelementptr inbounds nuw i8, ptr %a, i64 24, !dbg !390
  %0 = load i32, ptr %count, align 4, !dbg !390
  %count1 = getelementptr inbounds nuw i8, ptr %b, i64 24, !dbg !392
  %1 = load i32, ptr %count1, align 4, !dbg !392
  %cmp.not = icmp eq i32 %0, %1, !dbg !393
  br i1 %cmp.not, label %if.end, label %if.then, !dbg !393

if.then:                                          ; preds = %entry
  %sub = sub nsw i32 %1, %0, !dbg !394
  br label %return, !dbg !396

if.end:                                           ; preds = %entry
  %first_seen = getelementptr inbounds nuw i8, ptr %a, i64 28, !dbg !397
  %2 = load i32, ptr %first_seen, align 4, !dbg !397
  %first_seen4 = getelementptr inbounds nuw i8, ptr %b, i64 28, !dbg !398
  %3 = load i32, ptr %first_seen4, align 4, !dbg !398
  %sub5 = sub nsw i32 %2, %3, !dbg !399
  br label %return, !dbg !400

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32 [ %sub, %if.then ], [ %sub5, %if.end ], !dbg !386
  ret i32 %retval.0, !dbg !401
}

; Function Attrs: noinline nounwind uwtable
define internal void @print_bar(i32 noundef %count, i32 noundef %widest) #0 !dbg !402 {
entry:
    #dbg_value(i32 %count, !405, !DIExpression(), !406)
    #dbg_value(i32 %widest, !407, !DIExpression(), !406)
  %cmp = icmp sgt i32 %widest, 0, !dbg !408
  br i1 %cmp, label %cond.true, label %cond.end, !dbg !409

cond.true:                                        ; preds = %entry
  %mul = mul nsw i32 %count, 30, !dbg !410
  %div = sdiv i32 %mul, %widest, !dbg !411
  br label %cond.end, !dbg !409

cond.end:                                         ; preds = %cond.true, %entry
  %cond = phi i32 [ %div, %cond.true ], [ 0, %entry ], !dbg !409
    #dbg_value(i32 %cond, !412, !DIExpression(), !406)
    #dbg_value(i32 0, !413, !DIExpression(), !415)
  br label %for.cond, !dbg !416

for.cond:                                         ; preds = %for.body, %cond.end
  %i.0 = phi i32 [ 0, %cond.end ], [ %inc, %for.body ], !dbg !417
    #dbg_value(i32 %i.0, !413, !DIExpression(), !415)
  %cmp1 = icmp slt i32 %i.0, %cond, !dbg !418
  br i1 %cmp1, label %for.body, label %for.end, !dbg !420

for.body:                                         ; preds = %for.cond
  %call = call i32 @putchar(i32 noundef 35) #7, !dbg !421
  %inc = add nuw nsw i32 %i.0, 1, !dbg !423
    #dbg_value(i32 %inc, !413, !DIExpression(), !415)
  br label %for.cond, !dbg !424, !llvm.loop !425

for.end:                                          ; preds = %for.cond
  %call2 = call i32 @putchar(i32 noundef 10) #7, !dbg !427
  ret void, !dbg !428
}

; Function Attrs: noinline nounwind uwtable
define internal ptr @longest(ptr noundef %entries, i32 noundef %n) #0 !dbg !429 {
entry:
    #dbg_value(ptr %entries, !432, !DIExpression(), !433)
    #dbg_value(i32 %n, !434, !DIExpression(), !433)
    #dbg_value(ptr null, !435, !DIExpression(), !433)
    #dbg_value(i64 0, !436, !DIExpression(), !433)
    #dbg_value(i32 0, !437, !DIExpression(), !439)
  br label %for.cond, !dbg !440

for.cond:                                         ; preds = %for.body, %entry
  %best.0 = phi ptr [ null, %entry ], [ %best.1, %for.body ], !dbg !433
  %best_length.0 = phi i64 [ 0, %entry ], [ %best_length.1, %for.body ], !dbg !433
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ], !dbg !441
    #dbg_value(i32 %i.0, !437, !DIExpression(), !439)
    #dbg_value(i64 %best_length.0, !436, !DIExpression(), !433)
    #dbg_value(ptr %best.0, !435, !DIExpression(), !433)
  %cmp = icmp slt i32 %i.0, %n, !dbg !442
  br i1 %cmp, label %for.body, label %for.end, !dbg !444

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !445
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !445
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx) #9, !dbg !447
    #dbg_value(i64 %call, !448, !DIExpression(), !449)
  %cmp1 = icmp ugt i64 %call, %best_length.0, !dbg !450
  %best.1 = select i1 %cmp1, ptr %arrayidx, ptr %best.0, !dbg !450
  %best_length.1 = select i1 %cmp1, i64 %call, i64 %best_length.0, !dbg !450
    #dbg_value(i64 %best_length.1, !436, !DIExpression(), !433)
    #dbg_value(ptr %best.1, !435, !DIExpression(), !433)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !452
    #dbg_value(i32 %inc, !437, !DIExpression(), !439)
  br label %for.cond, !dbg !453, !llvm.loop !454

for.end:                                          ; preds = %for.cond
  ret ptr %best.0, !dbg !456
}

; Function Attrs: noinline nounwind uwtable
define internal double @mean_length(ptr noundef %entries, i32 noundef %n) #0 !dbg !457 {
entry:
    #dbg_value(ptr %entries, !460, !DIExpression(), !461)
    #dbg_value(i32 %n, !462, !DIExpression(), !461)
    #dbg_value(i64 0, !463, !DIExpression(), !461)
    #dbg_value(i64 0, !464, !DIExpression(), !461)
    #dbg_value(i32 0, !465, !DIExpression(), !467)
  br label %for.cond, !dbg !468

for.cond:                                         ; preds = %for.inc, %entry
  %letters.0 = phi i64 [ 0, %entry ], [ %add, %for.inc ], !dbg !461
  %words.0 = phi i64 [ 0, %entry ], [ %add7, %for.inc ], !dbg !461
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !469
    #dbg_value(i32 %i.0, !465, !DIExpression(), !467)
    #dbg_value(i64 %words.0, !464, !DIExpression(), !461)
    #dbg_value(i64 %letters.0, !463, !DIExpression(), !461)
  %cmp = icmp slt i32 %i.0, %n, !dbg !470
  br i1 %cmp, label %for.inc, label %for.end, !dbg !472

for.inc:                                          ; preds = %for.cond
    #dbg_value(!DIArgList(i64 poison, i64 poison, i32 poison), !463, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !461)
    #dbg_value(!DIArgList(i64 poison, i32 poison), !464, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !461)
  %idxprom3 = zext nneg i32 %i.0 to i64, !dbg !473
  %arrayidx4 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom3, !dbg !473
  %count5 = getelementptr inbounds nuw i8, ptr %arrayidx4, i64 24, !dbg !475
  %0 = load i32, ptr %count5, align 4, !dbg !475
    #dbg_value(!DIArgList(i64 %words.0, i32 %0), !464, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !461)
  %conv6 = sext i32 %0 to i64, !dbg !473
    #dbg_value(!DIArgList(i64 %words.0, i64 %conv6), !464, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !461)
  %add7 = add nsw i64 %words.0, %conv6, !dbg !476
    #dbg_value(i64 %add7, !464, !DIExpression(), !461)
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx4) #9, !dbg !477
    #dbg_value(!DIArgList(i64 %letters.0, i64 %call, i32 %0), !463, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !461)
    #dbg_value(!DIArgList(i64 %letters.0, i64 %call, i64 %conv6), !463, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !461)
  %mul = mul nsw i64 %call, %conv6, !dbg !478
    #dbg_value(!DIArgList(i64 %letters.0, i64 %mul), !463, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !461)
  %add = add nsw i64 %letters.0, %mul, !dbg !479
    #dbg_value(i64 %add, !463, !DIExpression(), !461)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !480
    #dbg_value(i32 %inc, !465, !DIExpression(), !467)
  br label %for.cond, !dbg !481, !llvm.loop !482

for.end:                                          ; preds = %for.cond
  %cmp8 = icmp sgt i64 %words.0, 0, !dbg !484
  %conv10 = sitofp i64 %letters.0 to double, !dbg !485
  %conv11 = sitofp i64 %words.0 to double, !dbg !485
  %div = fdiv double %conv10, %conv11, !dbg !485
  %cond = select i1 %cmp8, double %div, double 0.000000e+00, !dbg !485
  ret double %cond, !dbg !486
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @singletons(ptr noundef %entries, i32 noundef %n) #0 !dbg !487 {
entry:
    #dbg_value(ptr %entries, !490, !DIExpression(), !491)
    #dbg_value(i32 %n, !492, !DIExpression(), !491)
    #dbg_value(i32 0, !493, !DIExpression(), !491)
    #dbg_value(i32 %n, !494, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !496)
  br label %for.cond, !dbg !497

for.cond:                                         ; preds = %for.inc, %entry
  %count.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !491
  %i.0.in = phi i32 [ %n, %entry ], [ %i.0, %for.inc ]
  %i.0 = add nsw i32 %i.0.in, -1, !dbg !498
    #dbg_value(i32 %i.0, !494, !DIExpression(), !496)
    #dbg_value(i32 %count.0, !493, !DIExpression(), !491)
  %cmp = icmp sgt i32 %i.0.in, 0, !dbg !499
  br i1 %cmp, label %land.rhs, label %for.end, !dbg !501

land.rhs:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !502
  %arrayidx = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom, !dbg !502
  %count1 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !503
  %0 = load i32, ptr %count1, align 4, !dbg !503
  %cmp2 = icmp eq i32 %0, 1, !dbg !504
  br i1 %cmp2, label %for.inc, label %for.end, !dbg !505

for.inc:                                          ; preds = %land.rhs
    #dbg_value(i32 %count.0, !493, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !491)
  %inc = add nuw nsw i32 %count.0, 1, !dbg !506
    #dbg_value(i32 %inc, !493, !DIExpression(), !491)
    #dbg_value(i32 %i.0, !494, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !496)
  br label %for.cond, !dbg !508, !llvm.loop !509

for.end:                                          ; preds = %land.rhs, %for.cond
  ret i32 %count.0, !dbg !511
}

declare i32 @putchar(i32 noundef) #1

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #5

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { nounwind }
attributes #8 = { cold nounwind }
attributes #9 = { nounwind willreturn memory(read) }
attributes #10 = { nounwind willreturn memory(none) }

!llvm.dbg.cu = !{!7}
!llvm.module.flags = !{!100, !101, !102, !103, !104, !105, !106}
!llvm.ident = !{!107}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "table", scope: !2, file: !3, line: 186, type: !96, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 185, type: !4, scopeLine: 185, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !7, retainedNodes: !95)
!3 = !DIFile(filename: "user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!4 = !DISubroutineType(types: !5)
!5 = !{!6}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !9, retainedTypes: !26, globals: !36, splitDebugInlining: false, nameTableKind: None)
!8 = !DIFile(filename: "/workspace/user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!9 = !{!10}
!10 = !DICompositeType(tag: DW_TAG_enumeration_type, file: !11, line: 46, baseType: !12, size: 32, elements: !13)
!11 = !DIFile(filename: "/usr/include/ctype.h", directory: "", checksumkind: CSK_MD5, checksum: "43fd45dcf96e8fb7d8f14700096497c7")
!12 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!13 = !{!14, !15, !16, !17, !18, !19, !20, !21, !22, !23, !24, !25}
!14 = !DIEnumerator(name: "_ISupper", value: 256)
!15 = !DIEnumerator(name: "_ISlower", value: 512)
!16 = !DIEnumerator(name: "_ISalpha", value: 1024)
!17 = !DIEnumerator(name: "_ISdigit", value: 2048)
!18 = !DIEnumerator(name: "_ISxdigit", value: 4096)
!19 = !DIEnumerator(name: "_ISspace", value: 8192)
!20 = !DIEnumerator(name: "_ISprint", value: 16384)
!21 = !DIEnumerator(name: "_ISgraph", value: 32768)
!22 = !DIEnumerator(name: "_ISblank", value: 1)
!23 = !DIEnumerator(name: "_IScntrl", value: 2)
!24 = !DIEnumerator(name: "_ISpunct", value: 4)
!25 = !DIEnumerator(name: "_ISalnum", value: 8)
!26 = !{!6, !27, !28, !29, !30, !33, !34, !35}
!27 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!28 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!29 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!30 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !31, line: 18, baseType: !32)
!31 = !DIFile(filename: "/opt/llvm/lib/clang/22/include/__stddef_size_t.h", directory: "", checksumkind: CSK_MD5, checksum: "2c44e821a2b1951cde2eb0fb2e656867")
!32 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!33 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!34 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!35 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!36 = !{!0, !37, !50, !55, !57, !62, !67, !72, !76, !78, !83, !85, !90}
!37 = !DIGlobalVariableExpression(var: !38, expr: !DIExpression())
!38 = distinct !DIGlobalVariable(name: "entries", scope: !2, file: !3, line: 187, type: !39, isLocal: true, isDefinition: true)
!39 = !DICompositeType(tag: DW_TAG_array_type, baseType: !40, size: 65536, elements: !48)
!40 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "entry", file: !3, line: 12, size: 256, elements: !41)
!41 = !{!42, !46, !47}
!42 = !DIDerivedType(tag: DW_TAG_member, name: "word", scope: !40, file: !3, line: 13, baseType: !43, size: 192)
!43 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 192, elements: !44)
!44 = !{!45}
!45 = !DISubrange(count: 24)
!46 = !DIDerivedType(tag: DW_TAG_member, name: "count", scope: !40, file: !3, line: 14, baseType: !6, size: 32, offset: 192)
!47 = !DIDerivedType(tag: DW_TAG_member, name: "first_seen", scope: !40, file: !3, line: 15, baseType: !6, size: 32, offset: 224)
!48 = !{!49}
!49 = !DISubrange(count: 256)
!50 = !DIGlobalVariableExpression(var: !51, expr: !DIExpression())
!51 = distinct !DIGlobalVariable(scope: null, file: !3, line: 192, type: !52, isLocal: true, isDefinition: true)
!52 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 32, elements: !53)
!53 = !{!54}
!54 = !DISubrange(count: 4)
!55 = !DIGlobalVariableExpression(var: !56, expr: !DIExpression())
!56 = distinct !DIGlobalVariable(scope: null, file: !3, line: 193, type: !52, isLocal: true, isDefinition: true)
!57 = !DIGlobalVariableExpression(var: !58, expr: !DIExpression())
!58 = distinct !DIGlobalVariable(scope: null, file: !3, line: 194, type: !59, isLocal: true, isDefinition: true)
!59 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 144, elements: !60)
!60 = !{!61}
!61 = !DISubrange(count: 18)
!62 = !DIGlobalVariableExpression(var: !63, expr: !DIExpression())
!63 = distinct !DIGlobalVariable(scope: null, file: !3, line: 102, type: !64, isLocal: true, isDefinition: true)
!64 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 184, elements: !65)
!65 = !{!66}
!66 = !DISubrange(count: 23)
!67 = !DIGlobalVariableExpression(var: !68, expr: !DIExpression())
!68 = distinct !DIGlobalVariable(scope: null, file: !3, line: 24, type: !69, isLocal: true, isDefinition: true)
!69 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 2280, elements: !70)
!70 = !{!71}
!71 = !DISubrange(count: 285)
!72 = !DIGlobalVariableExpression(var: !73, expr: !DIExpression())
!73 = distinct !DIGlobalVariable(name: "passage", scope: !7, file: !3, line: 23, type: !74, isLocal: true, isDefinition: true)
!74 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !75, size: 64)
!75 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !29)
!76 = !DIGlobalVariableExpression(var: !77, expr: !DIExpression())
!77 = distinct !DIGlobalVariable(scope: null, file: !3, line: 172, type: !64, isLocal: true, isDefinition: true)
!78 = !DIGlobalVariableExpression(var: !79, expr: !DIExpression())
!79 = distinct !DIGlobalVariable(scope: null, file: !3, line: 174, type: !80, isLocal: true, isDefinition: true)
!80 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 88, elements: !81)
!81 = !{!82}
!82 = !DISubrange(count: 11)
!83 = !DIGlobalVariableExpression(var: !84, expr: !DIExpression())
!84 = distinct !DIGlobalVariable(scope: null, file: !3, line: 179, type: !59, isLocal: true, isDefinition: true)
!85 = !DIGlobalVariableExpression(var: !86, expr: !DIExpression())
!86 = distinct !DIGlobalVariable(scope: null, file: !3, line: 181, type: !87, isLocal: true, isDefinition: true)
!87 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 216, elements: !88)
!88 = !{!89}
!89 = !DISubrange(count: 27)
!90 = !DIGlobalVariableExpression(var: !91, expr: !DIExpression())
!91 = distinct !DIGlobalVariable(scope: null, file: !3, line: 182, type: !92, isLocal: true, isDefinition: true)
!92 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 168, elements: !93)
!93 = !{!94}
!94 = !DISubrange(count: 21)
!95 = !{}
!96 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "table", file: !3, line: 18, size: 65568, elements: !97)
!97 = !{!98, !99}
!98 = !DIDerivedType(tag: DW_TAG_member, name: "slots", scope: !96, file: !3, line: 19, baseType: !39, size: 65536)
!99 = !DIDerivedType(tag: DW_TAG_member, name: "used", scope: !96, file: !3, line: 20, baseType: !6, size: 32, offset: 65536)
!100 = !{i32 7, !"Dwarf Version", i32 5}
!101 = !{i32 2, !"Debug Info Version", i32 3}
!102 = !{i32 1, !"wchar_size", i32 4}
!103 = !{i32 8, !"PIC Level", i32 2}
!104 = !{i32 7, !"PIE Level", i32 2}
!105 = !{i32 7, !"uwtable", i32 2}
!106 = !{i32 7, !"frame-pointer", i32 2}
!107 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!108 = !DILocation(line: 188, column: 5, scope: !2)
!109 = !DILocation(line: 189, column: 37, scope: !2)
!110 = !DILocation(line: 189, column: 17, scope: !2)
!111 = !DILocalVariable(name: "total", scope: !2, file: !3, line: 189, type: !6)
!112 = !DILocation(line: 0, scope: !2)
!113 = !DILocation(line: 190, column: 13, scope: !2)
!114 = !DILocalVariable(name: "n", scope: !2, file: !3, line: 190, type: !6)
!115 = !DILocation(line: 191, column: 5, scope: !2)
!116 = !DILocation(line: 192, column: 17, scope: !2)
!117 = !DILocalVariable(name: "foxes", scope: !2, file: !3, line: 192, type: !6)
!118 = !DILocation(line: 193, column: 16, scope: !2)
!119 = !DILocalVariable(name: "cats", scope: !2, file: !3, line: 193, type: !6)
!120 = !DILocation(line: 194, column: 5, scope: !2)
!121 = !DILocation(line: 195, column: 18, scope: !2)
!122 = !DILocation(line: 195, column: 22, scope: !2)
!123 = !DILocation(line: 195, column: 5, scope: !2)
!124 = distinct !DISubprogram(name: "table_init", scope: !3, file: !3, line: 39, type: !125, scopeLine: 39, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!125 = !DISubroutineType(types: !126)
!126 = !{null, !127}
!127 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !96, size: 64)
!128 = !DILocalVariable(name: "table", arg: 1, scope: !124, file: !3, line: 39, type: !127)
!129 = !DILocation(line: 0, scope: !124)
!130 = !DILocation(line: 40, column: 5, scope: !124)
!131 = !DILocation(line: 41, column: 1, scope: !124)
!132 = distinct !DISubprogram(name: "count_words", scope: !3, file: !3, line: 97, type: !133, scopeLine: 97, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!133 = !DISubroutineType(types: !134)
!134 = !{!6, !127, !74}
!135 = !DILocalVariable(name: "table", arg: 1, scope: !132, file: !3, line: 97, type: !127)
!136 = !DILocation(line: 0, scope: !132)
!137 = !DILocalVariable(name: "text", arg: 2, scope: !132, file: !3, line: 97, type: !74)
!138 = !DILocalVariable(name: "word", scope: !132, file: !3, line: 98, type: !43)
!139 = !DILocation(line: 98, column: 10, scope: !132)
!140 = !DILocalVariable(name: "position", scope: !132, file: !3, line: 99, type: !6)
!141 = !DILocation(line: 100, column: 5, scope: !132)
!142 = !DILocation(line: 100, column: 12, scope: !132)
!143 = !DILocation(line: 100, column: 35, scope: !132)
!144 = !DILocation(line: 101, column: 13, scope: !145)
!145 = distinct !DILexicalBlock(scope: !146, file: !3, line: 101, column: 13)
!146 = distinct !DILexicalBlock(scope: !132, file: !3, line: 100, column: 40)
!147 = !DILocation(line: 101, column: 46, scope: !145)
!148 = !DILocation(line: 102, column: 21, scope: !149)
!149 = distinct !DILexicalBlock(scope: !145, file: !3, line: 101, column: 51)
!150 = !DILocation(line: 102, column: 13, scope: !149)
!151 = !DILocation(line: 103, column: 13, scope: !149)
!152 = !DILocation(line: 105, column: 17, scope: !146)
!153 = distinct !{!153, !141, !154, !155}
!154 = !DILocation(line: 106, column: 5, scope: !132)
!155 = !{!"llvm.loop.mustprogress"}
!156 = !DILocation(line: 107, column: 5, scope: !132)
!157 = distinct !DISubprogram(name: "collect", scope: !3, file: !3, line: 120, type: !158, scopeLine: 120, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!158 = !DISubroutineType(types: !159)
!159 = !{!6, !160, !162}
!160 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !161, size: 64)
!161 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !96)
!162 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!163 = !DILocalVariable(name: "table", arg: 1, scope: !157, file: !3, line: 120, type: !160)
!164 = !DILocation(line: 0, scope: !157)
!165 = !DILocalVariable(name: "out", arg: 2, scope: !157, file: !3, line: 120, type: !162)
!166 = !DILocalVariable(name: "n", scope: !157, file: !3, line: 121, type: !6)
!167 = !DILocalVariable(name: "i", scope: !168, file: !3, line: 122, type: !6)
!168 = distinct !DILexicalBlock(scope: !157, file: !3, line: 122, column: 5)
!169 = !DILocation(line: 0, scope: !168)
!170 = !DILocation(line: 122, column: 10, scope: !168)
!171 = !DILocation(line: 122, scope: !168)
!172 = !DILocation(line: 122, column: 23, scope: !173)
!173 = distinct !DILexicalBlock(scope: !168, file: !3, line: 122, column: 5)
!174 = !DILocation(line: 122, column: 5, scope: !168)
!175 = !DILocation(line: 123, column: 13, scope: !176)
!176 = distinct !DILexicalBlock(scope: !177, file: !3, line: 123, column: 13)
!177 = distinct !DILexicalBlock(scope: !173, file: !3, line: 122, column: 42)
!178 = !DILocation(line: 123, column: 29, scope: !176)
!179 = !DILocation(line: 123, column: 35, scope: !176)
!180 = !DILocation(line: 124, column: 18, scope: !181)
!181 = distinct !DILexicalBlock(scope: !176, file: !3, line: 123, column: 40)
!182 = !DILocation(line: 124, column: 13, scope: !181)
!183 = !DILocation(line: 124, column: 24, scope: !181)
!184 = !DILocation(line: 125, column: 9, scope: !181)
!185 = !DILocation(line: 122, column: 38, scope: !173)
!186 = !DILocation(line: 122, column: 5, scope: !173)
!187 = distinct !{!187, !174, !188, !155}
!188 = !DILocation(line: 126, column: 5, scope: !168)
!189 = !DILocation(line: 127, column: 16, scope: !157)
!190 = !DILocation(line: 127, column: 5, scope: !157)
!191 = !DILocation(line: 128, column: 5, scope: !157)
!192 = distinct !DISubprogram(name: "report", scope: !3, file: !3, line: 170, type: !193, scopeLine: 170, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!193 = !DISubroutineType(types: !194)
!194 = !{null, !195, !6, !6}
!195 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !196, size: 64)
!196 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !40)
!197 = !DILocalVariable(name: "entries", arg: 1, scope: !192, file: !3, line: 170, type: !195)
!198 = !DILocation(line: 0, scope: !192)
!199 = !DILocalVariable(name: "n", arg: 2, scope: !192, file: !3, line: 170, type: !6)
!200 = !DILocalVariable(name: "total", arg: 3, scope: !192, file: !3, line: 170, type: !6)
!201 = !DILocation(line: 171, column: 19, scope: !192)
!202 = !DILocation(line: 171, column: 17, scope: !192)
!203 = !DILocalVariable(name: "shown", scope: !192, file: !3, line: 171, type: !6)
!204 = !DILocation(line: 172, column: 5, scope: !192)
!205 = !DILocalVariable(name: "i", scope: !206, file: !3, line: 173, type: !6)
!206 = distinct !DILexicalBlock(scope: !192, file: !3, line: 173, column: 5)
!207 = !DILocation(line: 0, scope: !206)
!208 = !DILocation(line: 173, column: 10, scope: !206)
!209 = !DILocation(line: 173, scope: !206)
!210 = !DILocation(line: 173, column: 23, scope: !211)
!211 = distinct !DILexicalBlock(scope: !206, file: !3, line: 173, column: 5)
!212 = !DILocation(line: 173, column: 5, scope: !206)
!213 = !DILocation(line: 174, column: 30, scope: !214)
!214 = distinct !DILexicalBlock(scope: !211, file: !3, line: 173, column: 37)
!215 = !DILocation(line: 174, column: 58, scope: !214)
!216 = !DILocation(line: 174, column: 9, scope: !214)
!217 = !DILocation(line: 175, column: 30, scope: !214)
!218 = !DILocation(line: 175, column: 48, scope: !214)
!219 = !DILocation(line: 175, column: 9, scope: !214)
!220 = !DILocation(line: 173, column: 33, scope: !211)
!221 = !DILocation(line: 173, column: 5, scope: !211)
!222 = distinct !{!222, !212, !223, !155}
!223 = !DILocation(line: 176, column: 5, scope: !206)
!224 = !DILocation(line: 177, column: 32, scope: !192)
!225 = !DILocalVariable(name: "word", scope: !192, file: !3, line: 177, type: !195)
!226 = !DILocation(line: 178, column: 14, scope: !227)
!227 = distinct !DILexicalBlock(scope: !192, file: !3, line: 178, column: 9)
!228 = !DILocation(line: 179, column: 9, scope: !229)
!229 = distinct !DILexicalBlock(scope: !227, file: !3, line: 178, column: 23)
!230 = !DILocation(line: 180, column: 5, scope: !229)
!231 = !DILocation(line: 181, column: 43, scope: !192)
!232 = !DILocation(line: 181, column: 5, scope: !192)
!233 = !DILocation(line: 182, column: 37, scope: !192)
!234 = !DILocation(line: 182, column: 5, scope: !192)
!235 = !DILocation(line: 183, column: 1, scope: !192)
!236 = distinct !DISubprogram(name: "table_lookup", scope: !3, file: !3, line: 64, type: !237, scopeLine: 64, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!237 = !DISubroutineType(types: !238)
!238 = !{!6, !160, !74}
!239 = !DILocalVariable(name: "table", arg: 1, scope: !236, file: !3, line: 64, type: !160)
!240 = !DILocation(line: 0, scope: !236)
!241 = !DILocalVariable(name: "word", arg: 2, scope: !236, file: !3, line: 64, type: !74)
!242 = !DILocation(line: 65, column: 26, scope: !236)
!243 = !DILocalVariable(name: "index", scope: !236, file: !3, line: 65, type: !12)
!244 = !DILocalVariable(name: "probe", scope: !245, file: !3, line: 66, type: !6)
!245 = distinct !DILexicalBlock(scope: !236, file: !3, line: 66, column: 5)
!246 = !DILocation(line: 0, scope: !245)
!247 = !DILocation(line: 66, column: 10, scope: !245)
!248 = !DILocation(line: 66, scope: !245)
!249 = !DILocation(line: 66, column: 31, scope: !250)
!250 = distinct !DILexicalBlock(scope: !245, file: !3, line: 66, column: 5)
!251 = !DILocation(line: 66, column: 5, scope: !245)
!252 = !DILocation(line: 67, column: 37, scope: !253)
!253 = distinct !DILexicalBlock(scope: !250, file: !3, line: 66, column: 54)
!254 = !DILocalVariable(name: "slot", scope: !253, file: !3, line: 67, type: !195)
!255 = !DILocation(line: 0, scope: !253)
!256 = !DILocation(line: 68, column: 19, scope: !257)
!257 = distinct !DILexicalBlock(scope: !253, file: !3, line: 68, column: 13)
!258 = !DILocation(line: 68, column: 25, scope: !257)
!259 = !DILocation(line: 71, column: 13, scope: !260)
!260 = distinct !DILexicalBlock(scope: !253, file: !3, line: 71, column: 13)
!261 = !DILocation(line: 71, column: 38, scope: !260)
!262 = !DILocation(line: 72, column: 13, scope: !263)
!263 = distinct !DILexicalBlock(scope: !260, file: !3, line: 71, column: 44)
!264 = !DILocation(line: 74, column: 24, scope: !253)
!265 = !DILocation(line: 66, column: 50, scope: !250)
!266 = !DILocation(line: 66, column: 5, scope: !250)
!267 = distinct !{!267, !251, !268, !155}
!268 = !DILocation(line: 75, column: 5, scope: !245)
!269 = !DILocation(line: 77, column: 1, scope: !236)
!270 = distinct !DISubprogram(name: "next_word", scope: !3, file: !3, line: 80, type: !271, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!271 = !DISubroutineType(types: !272)
!272 = !{!6, !273, !274}
!273 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !74, size: 64)
!274 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !29, size: 64)
!275 = !DILocalVariable(name: "text", arg: 1, scope: !270, file: !3, line: 80, type: !273)
!276 = !DILocation(line: 0, scope: !270)
!277 = !DILocalVariable(name: "word", arg: 2, scope: !270, file: !3, line: 80, type: !274)
!278 = !DILocation(line: 81, column: 21, scope: !270)
!279 = !DILocalVariable(name: "p", scope: !270, file: !3, line: 81, type: !74)
!280 = !DILocation(line: 82, column: 5, scope: !270)
!281 = !DILocation(line: 82, column: 12, scope: !270)
!282 = !DILocation(line: 82, column: 15, scope: !270)
!283 = !DILocation(line: 82, column: 23, scope: !270)
!284 = !DILocation(line: 82, column: 27, scope: !270)
!285 = !DILocation(line: 82, column: 26, scope: !270)
!286 = !DILocation(line: 83, column: 10, scope: !287)
!287 = distinct !DILexicalBlock(scope: !270, file: !3, line: 82, column: 55)
!288 = distinct !{!288, !280, !289, !155}
!289 = !DILocation(line: 84, column: 5, scope: !270)
!290 = !DILocalVariable(name: "length", scope: !270, file: !3, line: 85, type: !6)
!291 = !DILocation(line: 86, column: 5, scope: !270)
!292 = !DILocation(line: 86, column: 35, scope: !270)
!293 = !DILocation(line: 86, column: 12, scope: !270)
!294 = !DILocation(line: 87, column: 20, scope: !295)
!295 = distinct !DILexicalBlock(scope: !296, file: !3, line: 87, column: 13)
!296 = distinct !DILexicalBlock(scope: !270, file: !3, line: 86, column: 40)
!297 = !DILocation(line: 88, column: 44, scope: !298)
!298 = distinct !DILexicalBlock(scope: !295, file: !3, line: 87, column: 36)
!299 = !DILocation(line: 88, column: 36, scope: !298)
!300 = !DILocation(line: 88, column: 30, scope: !298)
!301 = !DILocation(line: 88, column: 24, scope: !298)
!302 = !DILocation(line: 88, column: 13, scope: !298)
!303 = !DILocation(line: 88, column: 28, scope: !298)
!304 = !DILocation(line: 89, column: 9, scope: !298)
!305 = !DILocation(line: 90, column: 10, scope: !296)
!306 = distinct !{!306, !291, !307, !155}
!307 = !DILocation(line: 91, column: 5, scope: !270)
!308 = !DILocation(line: 92, column: 5, scope: !270)
!309 = !DILocation(line: 92, column: 18, scope: !270)
!310 = !DILocation(line: 93, column: 11, scope: !270)
!311 = !DILocation(line: 94, column: 5, scope: !270)
!312 = distinct !DISubprogram(name: "table_add", scope: !3, file: !3, line: 44, type: !313, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!313 = !DISubroutineType(types: !314)
!314 = !{!6, !127, !74, !6}
!315 = !DILocalVariable(name: "table", arg: 1, scope: !312, file: !3, line: 44, type: !127)
!316 = !DILocation(line: 0, scope: !312)
!317 = !DILocalVariable(name: "word", arg: 2, scope: !312, file: !3, line: 44, type: !74)
!318 = !DILocalVariable(name: "position", arg: 3, scope: !312, file: !3, line: 44, type: !6)
!319 = !DILocation(line: 45, column: 26, scope: !312)
!320 = !DILocalVariable(name: "index", scope: !312, file: !3, line: 45, type: !12)
!321 = !DILocalVariable(name: "probe", scope: !322, file: !3, line: 46, type: !6)
!322 = distinct !DILexicalBlock(scope: !312, file: !3, line: 46, column: 5)
!323 = !DILocation(line: 0, scope: !322)
!324 = !DILocation(line: 46, column: 10, scope: !322)
!325 = !DILocation(line: 46, scope: !322)
!326 = !DILocation(line: 46, column: 31, scope: !327)
!327 = distinct !DILexicalBlock(scope: !322, file: !3, line: 46, column: 5)
!328 = !DILocation(line: 46, column: 5, scope: !322)
!329 = !DILocation(line: 47, column: 31, scope: !330)
!330 = distinct !DILexicalBlock(scope: !327, file: !3, line: 46, column: 54)
!331 = !DILocalVariable(name: "slot", scope: !330, file: !3, line: 47, type: !162)
!332 = !DILocation(line: 0, scope: !330)
!333 = !DILocation(line: 48, column: 19, scope: !334)
!334 = distinct !DILexicalBlock(scope: !330, file: !3, line: 48, column: 13)
!335 = !DILocation(line: 48, column: 25, scope: !334)
!336 = !DILocation(line: 49, column: 13, scope: !337)
!337 = distinct !DILexicalBlock(scope: !334, file: !3, line: 48, column: 31)
!338 = !DILocation(line: 50, column: 25, scope: !337)
!339 = !DILocation(line: 51, column: 19, scope: !337)
!340 = !DILocation(line: 51, column: 30, scope: !337)
!341 = !DILocation(line: 52, column: 20, scope: !337)
!342 = !DILocation(line: 52, column: 24, scope: !337)
!343 = !DILocation(line: 53, column: 13, scope: !337)
!344 = !DILocation(line: 55, column: 13, scope: !345)
!345 = distinct !DILexicalBlock(scope: !330, file: !3, line: 55, column: 13)
!346 = !DILocation(line: 55, column: 38, scope: !345)
!347 = !DILocation(line: 56, column: 24, scope: !348)
!348 = distinct !DILexicalBlock(scope: !345, file: !3, line: 55, column: 44)
!349 = !DILocation(line: 57, column: 13, scope: !348)
!350 = !DILocation(line: 59, column: 24, scope: !330)
!351 = !DILocation(line: 46, column: 50, scope: !327)
!352 = !DILocation(line: 46, column: 5, scope: !327)
!353 = distinct !{!353, !328, !354, !155}
!354 = !DILocation(line: 60, column: 5, scope: !322)
!355 = !DILocation(line: 62, column: 1, scope: !312)
!356 = distinct !DISubprogram(name: "hash_word", scope: !3, file: !3, line: 30, type: !357, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!357 = !DISubroutineType(types: !358)
!358 = !{!12, !74}
!359 = !DILocalVariable(name: "word", arg: 1, scope: !356, file: !3, line: 30, type: !74)
!360 = !DILocation(line: 0, scope: !356)
!361 = !DILocalVariable(name: "hash", scope: !356, file: !3, line: 31, type: !12)
!362 = !DILocalVariable(name: "p", scope: !363, file: !3, line: 32, type: !74)
!363 = distinct !DILexicalBlock(scope: !356, file: !3, line: 32, column: 5)
!364 = !DILocation(line: 0, scope: !363)
!365 = !DILocation(line: 32, column: 10, scope: !363)
!366 = !DILocation(line: 32, scope: !363)
!367 = !DILocation(line: 32, column: 32, scope: !368)
!368 = distinct !DILexicalBlock(scope: !363, file: !3, line: 32, column: 5)
!369 = !DILocation(line: 32, column: 35, scope: !368)
!370 = !DILocation(line: 32, column: 5, scope: !363)
!371 = !DILocation(line: 33, column: 17, scope: !372)
!372 = distinct !DILexicalBlock(scope: !368, file: !3, line: 32, column: 49)
!373 = !DILocation(line: 33, column: 14, scope: !372)
!374 = !DILocation(line: 34, column: 14, scope: !372)
!375 = !DILocation(line: 32, column: 45, scope: !368)
!376 = !DILocation(line: 32, column: 5, scope: !368)
!377 = distinct !{!377, !370, !378, !155}
!378 = !DILocation(line: 35, column: 5, scope: !363)
!379 = !DILocation(line: 36, column: 5, scope: !356)
!380 = distinct !DISubprogram(name: "by_count", scope: !3, file: !3, line: 111, type: !381, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!381 = !DISubroutineType(types: !382)
!382 = !{!6, !383, !383}
!383 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !384, size: 64)
!384 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!385 = !DILocalVariable(name: "a", arg: 1, scope: !380, file: !3, line: 111, type: !383)
!386 = !DILocation(line: 0, scope: !380)
!387 = !DILocalVariable(name: "b", arg: 2, scope: !380, file: !3, line: 111, type: !383)
!388 = !DILocalVariable(name: "x", scope: !380, file: !3, line: 112, type: !195)
!389 = !DILocalVariable(name: "y", scope: !380, file: !3, line: 113, type: !195)
!390 = !DILocation(line: 114, column: 12, scope: !391)
!391 = distinct !DILexicalBlock(scope: !380, file: !3, line: 114, column: 9)
!392 = !DILocation(line: 114, column: 24, scope: !391)
!393 = !DILocation(line: 114, column: 18, scope: !391)
!394 = !DILocation(line: 115, column: 25, scope: !395)
!395 = distinct !DILexicalBlock(scope: !391, file: !3, line: 114, column: 31)
!396 = !DILocation(line: 115, column: 9, scope: !395)
!397 = !DILocation(line: 117, column: 15, scope: !380)
!398 = !DILocation(line: 117, column: 31, scope: !380)
!399 = !DILocation(line: 117, column: 26, scope: !380)
!400 = !DILocation(line: 117, column: 5, scope: !380)
!401 = !DILocation(line: 118, column: 1, scope: !380)
!402 = distinct !DISubprogram(name: "print_bar", scope: !3, file: !3, line: 162, type: !403, scopeLine: 162, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!403 = !DISubroutineType(types: !404)
!404 = !{null, !6, !6}
!405 = !DILocalVariable(name: "count", arg: 1, scope: !402, file: !3, line: 162, type: !6)
!406 = !DILocation(line: 0, scope: !402)
!407 = !DILocalVariable(name: "widest", arg: 2, scope: !402, file: !3, line: 162, type: !6)
!408 = !DILocation(line: 163, column: 24, scope: !402)
!409 = !DILocation(line: 163, column: 17, scope: !402)
!410 = !DILocation(line: 163, column: 36, scope: !402)
!411 = !DILocation(line: 163, column: 41, scope: !402)
!412 = !DILocalVariable(name: "width", scope: !402, file: !3, line: 163, type: !6)
!413 = !DILocalVariable(name: "i", scope: !414, file: !3, line: 164, type: !6)
!414 = distinct !DILexicalBlock(scope: !402, file: !3, line: 164, column: 5)
!415 = !DILocation(line: 0, scope: !414)
!416 = !DILocation(line: 164, column: 10, scope: !414)
!417 = !DILocation(line: 164, scope: !414)
!418 = !DILocation(line: 164, column: 23, scope: !419)
!419 = distinct !DILexicalBlock(scope: !414, file: !3, line: 164, column: 5)
!420 = !DILocation(line: 164, column: 5, scope: !414)
!421 = !DILocation(line: 165, column: 9, scope: !422)
!422 = distinct !DILexicalBlock(scope: !419, file: !3, line: 164, column: 37)
!423 = !DILocation(line: 164, column: 33, scope: !419)
!424 = !DILocation(line: 164, column: 5, scope: !419)
!425 = distinct !{!425, !420, !426, !155}
!426 = !DILocation(line: 166, column: 5, scope: !414)
!427 = !DILocation(line: 167, column: 5, scope: !402)
!428 = !DILocation(line: 168, column: 1, scope: !402)
!429 = distinct !DISubprogram(name: "longest", scope: !3, file: !3, line: 141, type: !430, scopeLine: 141, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!430 = !DISubroutineType(types: !431)
!431 = !{!195, !195, !6}
!432 = !DILocalVariable(name: "entries", arg: 1, scope: !429, file: !3, line: 141, type: !195)
!433 = !DILocation(line: 0, scope: !429)
!434 = !DILocalVariable(name: "n", arg: 2, scope: !429, file: !3, line: 141, type: !6)
!435 = !DILocalVariable(name: "best", scope: !429, file: !3, line: 142, type: !195)
!436 = !DILocalVariable(name: "best_length", scope: !429, file: !3, line: 143, type: !30)
!437 = !DILocalVariable(name: "i", scope: !438, file: !3, line: 144, type: !6)
!438 = distinct !DILexicalBlock(scope: !429, file: !3, line: 144, column: 5)
!439 = !DILocation(line: 0, scope: !438)
!440 = !DILocation(line: 144, column: 10, scope: !438)
!441 = !DILocation(line: 144, scope: !438)
!442 = !DILocation(line: 144, column: 23, scope: !443)
!443 = distinct !DILexicalBlock(scope: !438, file: !3, line: 144, column: 5)
!444 = !DILocation(line: 144, column: 5, scope: !438)
!445 = !DILocation(line: 145, column: 32, scope: !446)
!446 = distinct !DILexicalBlock(scope: !443, file: !3, line: 144, column: 33)
!447 = !DILocation(line: 145, column: 25, scope: !446)
!448 = !DILocalVariable(name: "length", scope: !446, file: !3, line: 145, type: !30)
!449 = !DILocation(line: 0, scope: !446)
!450 = !DILocation(line: 146, column: 20, scope: !451)
!451 = distinct !DILexicalBlock(scope: !446, file: !3, line: 146, column: 13)
!452 = !DILocation(line: 144, column: 29, scope: !443)
!453 = !DILocation(line: 144, column: 5, scope: !443)
!454 = distinct !{!454, !444, !455, !155}
!455 = !DILocation(line: 150, column: 5, scope: !438)
!456 = !DILocation(line: 151, column: 5, scope: !429)
!457 = distinct !DISubprogram(name: "mean_length", scope: !3, file: !3, line: 131, type: !458, scopeLine: 131, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!458 = !DISubroutineType(types: !459)
!459 = !{!35, !195, !6}
!460 = !DILocalVariable(name: "entries", arg: 1, scope: !457, file: !3, line: 131, type: !195)
!461 = !DILocation(line: 0, scope: !457)
!462 = !DILocalVariable(name: "n", arg: 2, scope: !457, file: !3, line: 131, type: !6)
!463 = !DILocalVariable(name: "letters", scope: !457, file: !3, line: 132, type: !34)
!464 = !DILocalVariable(name: "words", scope: !457, file: !3, line: 133, type: !34)
!465 = !DILocalVariable(name: "i", scope: !466, file: !3, line: 134, type: !6)
!466 = distinct !DILexicalBlock(scope: !457, file: !3, line: 134, column: 5)
!467 = !DILocation(line: 0, scope: !466)
!468 = !DILocation(line: 134, column: 10, scope: !466)
!469 = !DILocation(line: 134, scope: !466)
!470 = !DILocation(line: 134, column: 23, scope: !471)
!471 = distinct !DILexicalBlock(scope: !466, file: !3, line: 134, column: 5)
!472 = !DILocation(line: 134, column: 5, scope: !466)
!473 = !DILocation(line: 136, column: 18, scope: !474)
!474 = distinct !DILexicalBlock(scope: !471, file: !3, line: 134, column: 33)
!475 = !DILocation(line: 136, column: 29, scope: !474)
!476 = !DILocation(line: 136, column: 15, scope: !474)
!477 = !DILocation(line: 135, column: 26, scope: !474)
!478 = !DILocation(line: 135, column: 50, scope: !474)
!479 = !DILocation(line: 135, column: 17, scope: !474)
!480 = !DILocation(line: 134, column: 29, scope: !471)
!481 = !DILocation(line: 134, column: 5, scope: !471)
!482 = distinct !{!482, !472, !483, !155}
!483 = !DILocation(line: 137, column: 5, scope: !466)
!484 = !DILocation(line: 138, column: 18, scope: !457)
!485 = !DILocation(line: 138, column: 12, scope: !457)
!486 = !DILocation(line: 138, column: 5, scope: !457)
!487 = distinct !DISubprogram(name: "singletons", scope: !3, file: !3, line: 154, type: !488, scopeLine: 154, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!488 = !DISubroutineType(types: !489)
!489 = !{!6, !195, !6}
!490 = !DILocalVariable(name: "entries", arg: 1, scope: !487, file: !3, line: 154, type: !195)
!491 = !DILocation(line: 0, scope: !487)
!492 = !DILocalVariable(name: "n", arg: 2, scope: !487, file: !3, line: 154, type: !6)
!493 = !DILocalVariable(name: "count", scope: !487, file: !3, line: 155, type: !6)
!494 = !DILocalVariable(name: "i", scope: !495, file: !3, line: 156, type: !6)
!495 = distinct !DILexicalBlock(scope: !487, file: !3, line: 156, column: 5)
!496 = !DILocation(line: 0, scope: !495)
!497 = !DILocation(line: 156, column: 10, scope: !495)
!498 = !DILocation(line: 156, scope: !495)
!499 = !DILocation(line: 156, column: 27, scope: !500)
!500 = distinct !DILexicalBlock(scope: !495, file: !3, line: 156, column: 5)
!501 = !DILocation(line: 156, column: 32, scope: !500)
!502 = !DILocation(line: 156, column: 35, scope: !500)
!503 = !DILocation(line: 156, column: 46, scope: !500)
!504 = !DILocation(line: 156, column: 52, scope: !500)
!505 = !DILocation(line: 156, column: 5, scope: !495)
!506 = !DILocation(line: 157, column: 14, scope: !507)
!507 = distinct !DILexicalBlock(scope: !500, file: !3, line: 156, column: 63)
!508 = !DILocation(line: 156, column: 5, scope: !500)
!509 = distinct !{!509, !505, !510, !155}
!510 = !DILocation(line: 158, column: 5, scope: !495)
!511 = !DILocation(line: 159, column: 5, scope: !487)
