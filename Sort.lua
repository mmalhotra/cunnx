local Sort, parent = torch.class('nn.Sort', 'nn.Module')
------------------------------------------------------------------------
--[[ Sort ]]--
-- Applies torch.sort along dimension dim to the input.
-- Returns a table of {sortedInputs, sortedIndices}
-- Used with BlockSparse
------------------------------------------------------------------------

function Sort:__init(dim, descending)
   parent.__init(self)
   self.dim = dim or 2
   self.notDim = (self.dim == 2) and 1 or 2
   self.descending = descending or false
   
   self.indice = torch.LongTensor()
   self._output = torch.Tensor()
   self._input = torch.Tensor()
   self.output = {self._output, self.indice}
   self.cuda = false
end

function Sort:updateOutput(input)
   assert(input:dim() == 2, "Only works with matrices")
   if self.cuda then
      self._input:resize(input:size())
      self._input:copy(input)
      input = self._input
   end
   self._output:sort(self.indice, input, self.dim, self.descending)
   if self.cuda then
      self._outputCuda:resize(output:size())
      self._outputCuda:copy(self._output)
      self._indiceCuda:resize(self.indice:size())
      self._indiceCuda:copy(self.indice)
   end
   return self.output
end

function Sort:updateGradInput(input, gradOutput)
   local dim = self.notDim
   self.gradInput:resizeAs(input)
   for i=1,input:size(dim) do
      self.gradInput:select(dim, i):indexCopy(1, self.indice:select(dim, i), gradOutput[1]:select(dim, i))
   end
   return self.gradInput
end

function Sort:type(type)
   self.gradInput = self.gradInput:type(type)
   if (type ~= 'torch.CudaTensor') then
      self._output = self._output:type(type)
      self._input = self._input:type(type)
      self.output = {self._output, self.indice}
   else
      self.cuda = true
      self._output = self._output:float()
      self._input = self._input:float()
      self._outputCuda = torch.CudaTensor()
      self._indiceCuda = torch.CudaTensor()
      self.output = {self._outputCuda, self.indiceCuda}
   end
end


